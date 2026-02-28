import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/models.dart';
import '../services/realtime_voice_service.dart';
import 'app_state.dart';

enum VoiceSessionStatus { idle, connecting, listening, processingTool, agentSpeaking }

class VoiceState extends ChangeNotifier {
  final AppState _app;
  final CommandState _cmdState;

  VoiceSessionStatus _status = VoiceSessionStatus.idle;
  String? _lastError;

  RealtimeVoiceService? _service;
  AudioPlayer? _player;
  StreamSubscription? _playerCompleteSub;

  VoiceState(this._app, this._cmdState);

  VoiceSessionStatus get status => _status;
  bool get isActive => _status != VoiceSessionStatus.idle;
  String? get lastError => _lastError;

  /// Called on long-press start. Connects if needed, then unmutes mic.
  Future<void> startListening() async {
    _lastError = null;

    // Already connected — just unmute.
    if (_service != null && _service!.isConnected) {
      _service!.unmuteMic();
      _status = VoiceSessionStatus.listening;
      notifyListeners();
      return;
    }

    // Need to connect first.
    final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      _lastError = 'OPENAI_API_KEY not set in .env file.';
      notifyListeners();
      return;
    }
    final client = _app.client;
    if (client == null) {
      _lastError = 'Not connected to Atlas.';
      notifyListeners();
      return;
    }

    _status = VoiceSessionStatus.connecting;
    notifyListeners();

    _player = AudioPlayer();
    _playerCompleteSub = _player!.onPlayerComplete.listen((_) {
      // Audio finished playing — go back to idle (ready for next hold).
      if (_status == VoiceSessionStatus.agentSpeaking) {
        _status = VoiceSessionStatus.idle;
        notifyListeners();
      }
    });

    _service = RealtimeVoiceService(apiClient: client);

    _service!
      ..onStatusChange = (s) {
        _status = s;
        notifyListeners();
      }
      ..onUserTranscript = (text) {
        _cmdState.addVoiceMessage(ChatMessage(text: text, isUser: true));
      }
      ..onAiText = (text) {
        _cmdState.addVoiceMessage(ChatMessage(text: text, isUser: false));
      }
      ..onAiAudio = (Uint8List wav) async {
        await _player?.play(BytesSource(wav));
      }
      ..onInterrupt = () async {
        await _player?.stop();
      }
      ..onError = (err) {
        _lastError = err;
        _status = VoiceSessionStatus.idle;
        _cleanup();
        notifyListeners();
      }
      ..onDone = () {
        // WebSocket closed unexpectedly — clean up.
        _status = VoiceSessionStatus.idle;
        _cleanup();
        notifyListeners();
      };

    try {
      await _service!.connect(apiKey);
      // connect() starts mic streaming; unmute so audio flows.
      _service!.unmuteMic();
    } catch (e) {
      _lastError = 'Connection failed: $e';
      _status = VoiceSessionStatus.idle;
      _cleanup();
      notifyListeners();
    }
  }

  /// Called on long-press end. Mutes mic but keeps connection alive.
  void stopListening() {
    _service?.muteMic();
    // If we're still just listening (no response yet), go idle.
    // If processing/speaking, let it finish — status will update via callbacks.
    if (_status == VoiceSessionStatus.listening) {
      _status = VoiceSessionStatus.idle;
      notifyListeners();
    }
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  void _cleanup() {
    _playerCompleteSub?.cancel();
    _playerCompleteSub = null;
    _service = null;
    _player?.dispose();
    _player = null;
  }

  @override
  void dispose() {
    _service?.disconnect();
    _playerCompleteSub?.cancel();
    _player?.dispose();
    super.dispose();
  }
}
