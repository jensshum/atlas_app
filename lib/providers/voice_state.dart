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

  VoiceState(this._app, this._cmdState);

  VoiceSessionStatus get status => _status;
  bool get isActive => _status != VoiceSessionStatus.idle;
  String? get lastError => _lastError;

  Future<void> startSession() async {
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
    _lastError = null;
    notifyListeners();

    _player = AudioPlayer();
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
        _status = VoiceSessionStatus.idle;
        _cleanup();
        notifyListeners();
      };

    try {
      await _service!.connect(apiKey);
    } catch (e) {
      _lastError = 'Connection failed: $e';
      _status = VoiceSessionStatus.idle;
      _cleanup();
      notifyListeners();
    }
  }

  Future<void> stopSession() async {
    await _service?.disconnect();
    await _player?.stop();
    _cleanup();
    _status = VoiceSessionStatus.idle;
    _lastError = null;
    notifyListeners();
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  void _cleanup() {
    _service = null;
    _player?.dispose();
    _player = null;
  }

  @override
  void dispose() {
    _service?.disconnect();
    _player?.dispose();
    super.dispose();
  }
}
