import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../providers/voice_state.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late CommandState _commandState;
  late AppState _appState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _commandState = context.read<CommandState>();
      _commandState.addListener(_onStateChange);
      _appState = context.read<AppState>();
      _appState.addListener(_onAppStateChange);
      // Try preconnect now in case server is already connected.
      context.read<VoiceState>().preconnect();
    });
  }

  @override
  void dispose() {
    _commandState.removeListener(_onStateChange);
    _appState.removeListener(_onAppStateChange);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onAppStateChange() {
    // Preconnect to OpenAI once the Atlas server is found.
    if (_appState.connectionState == ServerConnectionState.connected) {
      context.read<VoiceState>().preconnect();
    }
  }

  void _onStateChange() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _send(CommandState state) {
    final text = _controller.text.trim();
    if (text.isEmpty || state.loading) return;
    _controller.clear();
    state.sendCommand(text);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CommandState, VoiceState>(
      builder: (context, state, voice, _) {
        return Column(
          children: [
            _VoiceBanner(voice: voice),
            Expanded(
              child: state.messages.isEmpty
                  ? const _EmptyHint()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount:
                          state.messages.length + (state.loading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.messages.length) {
                          return const _TypingIndicator();
                        }
                        return _MessageBubble(
                            message: state.messages[index]);
                      },
                    ),
            ),
            _InputBar(
              controller: _controller,
              loading: state.loading,
              onSend: () => _send(state),
              voice: voice,
            ),
          ],
        );
      },
    );
  }
}

// ─── Voice banner ─────────────────────────────────────────────────────────────

class _VoiceBanner extends StatelessWidget {
  final VoiceState voice;
  const _VoiceBanner({required this.voice});

  @override
  Widget build(BuildContext context) {
    final error = voice.lastError;

    if (!voice.isActive && error == null) return const SizedBox.shrink();

    if (error != null) {
      return Container(
        decoration: const BoxDecoration(
          color: AtlasColors.errorSurface,
          border: Border(
            bottom: BorderSide(
              color: AtlasColors.error,
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 16, color: AtlasColors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(
                    color: AtlasColors.error, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: voice.clearError,
              style: TextButton.styleFrom(
                foregroundColor: AtlasColors.error,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child:
                  const Text('Dismiss', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      );
    }

    final (IconData icon, String label, Color color) =
        switch (voice.status) {
      VoiceSessionStatus.connecting => (
        Icons.settings_ethernet_rounded,
        'Connecting to OpenAI...',
        AtlasColors.gold,
      ),
      VoiceSessionStatus.processingTool => (
        Icons.phone_android_rounded,
        'Atlas is working...',
        AtlasColors.gold,
      ),
      VoiceSessionStatus.agentSpeaking => (
        Icons.volume_up_rounded,
        'Speaking...',
        AtlasColors.info,
      ),
      _ => (
        Icons.mic_rounded,
        'Listening...',
        AtlasColors.success,
      ),
    };

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(
            color: color.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ─── Empty hint ───────────────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AtlasColors.goldSurface,
              border: Border.all(
                color: AtlasColors.gold.withValues(alpha: 0.15),
              ),
            ),
            child: Icon(
              Icons.terminal_rounded,
              size: 36,
              color: AtlasColors.gold.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Send a command to Atlas',
            style: TextStyle(
              color: AtlasColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '"Open Chrome and search for the weather"',
            style: TextStyle(
              color: AtlasColors.textTertiary,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Or hold the mic to use voice',
            style: TextStyle(
              color: AtlasColors.textTertiary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: isUser
              ? AtlasColors.goldSurface
              : AtlasColors.surfaceContainer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: Border.all(
            color: isUser
                ? AtlasColors.gold.withValues(alpha: 0.12)
                : AtlasColors.border,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isUser
                    ? AtlasColors.goldLight
                    : AtlasColors.textPrimary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            if (message.turns != null) ...[
              const SizedBox(height: 5),
              Text(
                '${message.turns} turns',
                style: const TextStyle(
                  fontSize: 11,
                  color: AtlasColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Animated typing indicator ────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AtlasColors.surfaceContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AtlasColors.border, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final phase = (_controller.value - i * 0.2) % 1.0;
                final dy =
                    -math.sin(phase * math.pi).clamp(0.0, 1.0) * 4.0;
                return Transform.translate(
                  offset: Offset(0, dy),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AtlasColors.gold.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSend;
  final VoiceState voice;

  const _InputBar({
    required this.controller,
    required this.loading,
    required this.onSend,
    required this.voice,
  });

  @override
  Widget build(BuildContext context) {
    final voiceActive = voice.isActive;

    return Container(
      decoration: const BoxDecoration(
        color: AtlasColors.surface,
        border: Border(
          top: BorderSide(color: AtlasColors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
          child: Row(
            children: [
              // ── Mic button ──
              GestureDetector(
                onLongPressStart: loading
                    ? null
                    : (_) => voice.startListening(),
                onLongPressEnd: loading
                    ? null
                    : (_) => voice.stopListening(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: voiceActive
                        ? AtlasColors.gold.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    voiceActive
                        ? Icons.mic_rounded
                        : Icons.mic_none_rounded,
                    size: 22,
                    color: loading
                        ? AtlasColors.textTertiary.withValues(alpha: 0.4)
                        : voiceActive
                            ? AtlasColors.gold
                            : AtlasColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // ── Text input ──
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  enabled: !loading && !voiceActive,
                  style: const TextStyle(fontSize: 14),
                  cursorColor: AtlasColors.gold,
                  decoration: InputDecoration(
                    hintText: voiceActive
                        ? 'Voice mode active...'
                        : 'Tell Atlas what to do...',
                    filled: true,
                    fillColor: AtlasColors.surfaceContainer,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: AtlasColors.border,
                        width: 0.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: AtlasColors.border,
                        width: 0.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color:
                            AtlasColors.gold.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: AtlasColors.border,
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // ── Send button ──
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (loading || voiceActive)
                      ? AtlasColors.surfaceContainerHigh
                      : AtlasColors.gold,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: (loading || voiceActive) ? null : onSend,
                    borderRadius: BorderRadius.circular(22),
                    child: Center(
                      child: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AtlasColors.textSecondary,
                              ),
                            )
                          : Icon(
                              Icons.arrow_upward_rounded,
                              size: 20,
                              color: (loading || voiceActive)
                                  ? AtlasColors.textTertiary
                                  : const Color(0xFF1A1507),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
