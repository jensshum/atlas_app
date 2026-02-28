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
  bool _preconnecting = false;

  RealtimeVoiceService? _service;
  AudioPlayer? _player;
  StreamSubscription? _playerCompleteSub;

  VoiceState(this._app, this._cmdState);

  VoiceSessionStatus get status => _status;
  bool get isActive => _status != VoiceSessionStatus.idle;
  String? get lastError => _lastError;

  /// Eagerly connect to OpenAI so the mic is instant when held.
  /// Called from the home screen on load. Fully silent — no errors shown.
  Future<void> preconnect() async {
    if (_preconnecting || (_service != null && _service!.isConnected)) return;
    // Don't attempt if prerequisites aren't ready yet.
    final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (apiKey.isEmpty || _app.client == null) return;
    _preconnecting = true;
    try {
      await _connect();
    } catch (_) {
      // Preconnect failure is silent — startListening will retry.
      _lastError = null;
    } finally {
      _preconnecting = false;
    }
  }

  /// Called on hold start. Unmutes mic instantly if pre-connected.
  Future<void> startListening() async {
    _lastError = null;

    if (_service != null && _service!.isConnected) {
      _service!.unmuteMic();
      _status = VoiceSessionStatus.listening;
      notifyListeners();
      return;
    }

    // Not pre-connected — connect now (fallback).
    _status = VoiceSessionStatus.connecting;
    notifyListeners();

    try {
      await _connect();
      _service!.unmuteMic();
    } catch (e) {
      _lastError = 'Connection failed: $e';
      _status = VoiceSessionStatus.idle;
      _cleanup();
      notifyListeners();
    }
  }

  /// Called on hold release. Mutes mic but keeps connection alive.
  void stopListening() {
    _service?.muteMic();
    if (_status == VoiceSessionStatus.listening) {
      _status = VoiceSessionStatus.idle;
      notifyListeners();
    }
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _connect() async {
    final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      _lastError = 'OPENAI_API_KEY not set in .env file.';
      notifyListeners();
      throw Exception(_lastError);
    }
    final client = _app.client;
    if (client == null) {
      _lastError = 'Not connected to Atlas.';
      notifyListeners();
      throw Exception(_lastError);
    }

    _player = AudioPlayer();
    _playerCompleteSub = _player!.onPlayerComplete.listen((_) {
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
        _status = VoiceSessionStatus.idle;
        _cleanup();
        notifyListeners();
      };

    await _service!.connect(apiKey);
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
