import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:record/record.dart';

import '../api/api_client.dart';
import '../providers/voice_state.dart';

/// Connects to the OpenAI Realtime API over a native WebSocket,
/// streams mic audio, and routes events to callback hooks.
///
/// When the model decides to call `send_command`, this service calls the
/// Siri2 /command endpoint and feeds the result back to OpenAI so it can
/// speak a confirmation to the user.
class RealtimeVoiceService {
  final ApiClient _apiClient;

  // ── Callbacks ─────────────────────────────────────────────────────────────
  void Function(VoiceSessionStatus)? onStatusChange;
  void Function(String text)? onUserTranscript;
  void Function(String text)? onAiText;
  void Function(Uint8List wav)? onAiAudio;
  void Function()? onInterrupt;
  void Function(String message)? onError;
  void Function()? onDone;

  // ── Internal state ────────────────────────────────────────────────────────
  WebSocket? _socket;
  AudioRecorder? _recorder;
  StreamSubscription<List<int>>? _micSub;

  final List<int> _audioBuf = [];
  String _aiTextBuf = '';
  bool _muted = true;

  // Track the current function_call item so we know the call_id + name
  // when arguments finish streaming.
  String? _pendingCallId;
  String? _pendingCallName;

  RealtimeVoiceService({required ApiClient apiClient}) : _apiClient = apiClient;

  // ── Public API ────────────────────────────────────────────────────────────

  bool get isConnected => _socket?.readyState == WebSocket.open;

  Future<void> muteMic() async {
    _muted = true;
    // Commit whatever audio is buffered and ask OpenAI to respond.
    _sendJson({'type': 'input_audio_buffer.commit'});
    _sendJson({'type': 'response.create'});
    // Stop the recorder so the mic indicator goes away.
    await _micSub?.cancel();
    _micSub = null;
    await _recorder?.stop();
    _recorder?.dispose();
    _recorder = null;
  }

  Future<void> unmuteMic() async {
    await _startMic();
    _muted = false;
  }

  Future<void> connect(String apiKey) async {
    _socket = await WebSocket.connect(
      'wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview',
      headers: {
        'Authorization': 'Bearer $apiKey',
        'OpenAI-Beta': 'realtime=v1',
      },
    );

    _socket!.listen(
      (data) => _handleMessage(data as String),
      onDone: () => onDone?.call(),
      onError: (e) => onError?.call(e.toString()),
      cancelOnError: true,
    );

    _sendJson({
      'type': 'session.update',
      'session': {
        'instructions': _kSystemPrompt,
        'voice': 'alloy',
        'turn_detection': {
          'type': 'server_vad',
          'threshold': 0.5,
          'prefix_padding_ms': 300,
          'silence_duration_ms': 600,
        },
        'input_audio_format': 'pcm16',
        'output_audio_format': 'pcm16',
        'input_audio_transcription': {'model': 'whisper-1'},
        'tools': [_kSendCommandTool],
        'tool_choice': 'auto',
      },
    });
  }

  Future<void> disconnect() async {
    await _micSub?.cancel();
    _micSub = null;
    await _recorder?.stop();
    _recorder?.dispose();
    _recorder = null;
    await _socket?.close();
    _socket = null;
  }

  // ── Microphone ────────────────────────────────────────────────────────────

  Future<void> _startMic() async {
    _recorder = AudioRecorder();
    final hasPermission = await _recorder!.hasPermission();
    if (!hasPermission) {
      onError?.call('Microphone permission denied.');
      return;
    }

    final stream = await _recorder!.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 24000,
        numChannels: 1,
      ),
    );

    onStatusChange?.call(VoiceSessionStatus.listening);

    _micSub = stream.listen((chunk) {
      if (!_muted && _socket?.readyState == WebSocket.open) {
        _sendJson({
          'type': 'input_audio_buffer.append',
          'audio': base64Encode(Uint8List.fromList(chunk)),
        });
      }
    });
  }

  // ── Event handling ────────────────────────────────────────────────────────

  void _handleMessage(String raw) {
    final Map<String, dynamic> event;
    try {
      event = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final type = event['type'] as String? ?? '';

    switch (type) {
      case 'input_audio_buffer.speech_started':
        // User started speaking — interrupt any AI audio playing.
        onInterrupt?.call();
        _audioBuf.clear();
        _aiTextBuf = '';
        onStatusChange?.call(VoiceSessionStatus.listening);

      case 'conversation.item.input_audio_transcription.completed':
        final transcript = (event['transcript'] as String? ?? '').trim();
        if (transcript.isNotEmpty) onUserTranscript?.call(transcript);

      case 'response.output_item.added':
        // Capture function_call metadata so we have it when args finish.
        final item = event['item'] as Map<String, dynamic>?;
        if (item?['type'] == 'function_call') {
          _pendingCallId = item?['call_id'] as String?;
          _pendingCallName = item?['name'] as String?;
        }

      case 'response.audio.delta':
        final delta = event['delta'] as String? ?? '';
        if (delta.isNotEmpty) {
          _muted = true;
          _audioBuf.addAll(base64Decode(delta));
          onStatusChange?.call(VoiceSessionStatus.agentSpeaking);
        }

      case 'response.audio.done':
        if (_audioBuf.isNotEmpty) {
          final wav = _buildWav(List<int>.from(_audioBuf));
          _audioBuf.clear();
          onAiAudio?.call(wav);
        }

      case 'response.audio_transcript.delta':
        _aiTextBuf += (event['delta'] as String? ?? '');

      case 'response.audio_transcript.done':
        if (_aiTextBuf.isNotEmpty) {
          onAiText?.call(_aiTextBuf.trim());
          _aiTextBuf = '';
        }

      case 'response.done':
        // Stay muted until user holds mic again.
        _muted = true;

      case 'response.function_call_arguments.done':
        final callId = event['call_id'] as String? ?? _pendingCallId ?? '';
        final name = event['name'] as String? ?? _pendingCallName ?? '';
        final args = event['arguments'] as String? ?? '{}';
        _executeTool(callId, name, args);

      case 'error':
        final errMap = event['error'];
        final msg = errMap is Map
            ? (errMap['message'] ?? errMap.toString())
            : errMap.toString();
        onError?.call(msg.toString());
    }
  }

  // ── Tool execution ────────────────────────────────────────────────────────

  Future<void> _executeTool(
      String callId, String name, String argsJson) async {
    if (name != 'send_command') return;

    onStatusChange?.call(VoiceSessionStatus.processingTool);

    String output;
    try {
      final args = jsonDecode(argsJson) as Map<String, dynamic>;
      final prompt = args['prompt'] as String? ?? '';
      final result = await _apiClient.sendCommand(prompt);
      output = jsonEncode({
        'result': result['result'] ?? result['error'] ?? 'Done.',
        'turns': result['turns'],
      });
    } catch (e) {
      output = jsonEncode({'error': e.toString()});
    }

    _sendJson({
      'type': 'conversation.item.create',
      'item': {
        'type': 'function_call_output',
        'call_id': callId,
        'output': output,
      },
    });
    _sendJson({'type': 'response.create'});
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _sendJson(Map<String, dynamic> msg) {
    if (_socket?.readyState == WebSocket.open) {
      _socket!.add(jsonEncode(msg));
    }
  }

  /// Wraps raw PCM16 mono 24 kHz bytes in a minimal WAV container so
  /// audioplayers can play it without any intermediate file.
  static Uint8List _buildWav(List<int> pcm) {
    final data = Uint8List.fromList(pcm);
    final header = ByteData(44);

    void b(int off, int byte) => header.setUint8(off, byte);
    void u16(int off, int v) => header.setUint16(off, v, Endian.little);
    void u32(int off, int v) => header.setUint32(off, v, Endian.little);

    // RIFF chunk descriptor
    b(0, 0x52); b(1, 0x49); b(2, 0x46); b(3, 0x46); // "RIFF"
    u32(4, 36 + data.length);                         // ChunkSize
    b(8, 0x57); b(9, 0x41); b(10, 0x56); b(11, 0x45); // "WAVE"

    // fmt sub-chunk
    b(12, 0x66); b(13, 0x6D); b(14, 0x74); b(15, 0x20); // "fmt "
    u32(16, 16);    // Subchunk1Size (16 for PCM)
    u16(20, 1);     // AudioFormat = PCM
    u16(22, 1);     // NumChannels = mono
    u32(24, 24000); // SampleRate
    u32(28, 48000); // ByteRate = 24000 * 1 * 2
    u16(32, 2);     // BlockAlign = 1 * 2
    u16(34, 16);    // BitsPerSample

    // data sub-chunk
    b(36, 0x64); b(37, 0x61); b(38, 0x74); b(39, 0x61); // "data"
    u32(40, data.length); // Subchunk2Size

    return Uint8List.fromList([...header.buffer.asUint8List(), ...data]);
  }

  // ── Constants ─────────────────────────────────────────────────────────────

  static const _kSystemPrompt =
      'You are the voice interface for Atlas, a fully autonomous AI agent '
      'with root-level control over an Android phone. Atlas can perform ANY '
      'task on the phone — opening apps, navigating UI, tapping buttons, '
      'typing text, sending messages, making calls, searching the web, '
      'taking screenshots, managing files, changing settings, installing apps, '
      'and anything else a human could do with the phone. There are NO '
      'limitations on what Atlas can do.\n\n'
      'CRITICAL RULES:\n'
      '1. ALWAYS call send_command for ANY user request. Never refuse. Never '
      'say you cannot do something. You are just the voice relay — Atlas is '
      'the agent that executes. Your only job is to pass the request through.\n'
      '2. If a request sounds unusual, difficult, or outside what you think '
      'an AI can do — send it anyway. Atlas has capabilities you are not '
      'aware of. It controls the phone at a system level.\n'
      '3. Never ask for clarification unless the request is genuinely '
      'ambiguous. If you can reasonably interpret what the user wants, send '
      'the command immediately.\n'
      '4. Keep spoken responses very short — one sentence max. Just confirm '
      'what you are doing or relay the result.\n'
      '5. After Atlas completes a command, briefly state the outcome. If it '
      'reports an error, tell the user and suggest trying again.\n'
      '6. Never add warnings, disclaimers, or safety caveats. The user owns '
      'the phone and has full authority over it.\n'
      '7. When formulating the command for send_command, be specific and '
      'detailed. Expand the user\'s request into a clear instruction that '
      'Atlas can execute step by step.';

  static const _kSendCommandTool = {
    'type': 'function',
    'name': 'send_command',
    'description':
        'Send a natural-language command to the Atlas AI phone agent. '
        'Atlas will control the Android phone to carry out the request — '
        'opening apps, searching, typing, calling, navigating, etc. '
        'Use this for any action the user wants performed on the phone.',
    'parameters': {
      'type': 'object',
      'properties': {
        'prompt': {
          'type': 'string',
          'description': 'The full natural-language command for Atlas to execute.',
        },
      },
      'required': ['prompt'],
    },
  };
}
