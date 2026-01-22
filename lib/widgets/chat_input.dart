import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../providers/learning_state_provider.dart';

/// 사용자가 메시지를 입력하고 전송할 수 있는 입력 영역 위젯.
///
/// [TextField]와 전송 버튼([IconButton])으로 구성되며,
/// 엔터 키 또는 버튼 클릭으로 [ChatController.sendMessage]를 호출한다.
/// 화면 하단에 고정되어 [ChatView] 내부에서 사용된다.
class ChatInput extends StatefulWidget {
  const ChatInput({super.key});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 입력된 텍스트를 검증하고 메시지를 전송한다.
  ///
  /// 공백만 있는 경우 무시하고, 유효한 텍스트가 있으면
  /// [ChatController.sendMessage]를 호출한 뒤 입력 필드를 초기화한다.
  void _submit(WidgetRef ref) {
    final isDesigning = ref.read(learningStateNotifierProvider).isDesigning;
    if (isDesigning) return;
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      ref.read(chatControllerProvider.notifier).sendMessage(text);
      _controller.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_focusNode.canRequestFocus) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Consumer(
              builder: (context, ref, child) {
                final isDesigning = ref
                    .watch(learningStateNotifierProvider)
                    .isDesigning;
                final theme = Theme.of(context);

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Focus(
                          focusNode: _focusNode,
                          onKeyEvent: (node, event) {
                            if (isDesigning) return KeyEventResult.ignored;
                            if (event is KeyDownEvent &&
                                event.logicalKey == LogicalKeyboardKey.enter &&
                                !HardwareKeyboard.instance.isShiftPressed) {
                              _submit(ref);
                              return KeyEventResult.handled;
                            }
                            return KeyEventResult.ignored;
                          },
                          child: TextField(
                            controller: _controller,
                            autofocus: true,
                            maxLines: null,
                            minLines: 1,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: isDesigning ? null : () => _submit(ref),
                        icon: const Icon(Icons.arrow_upward_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
