import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 입력된 텍스트를 검증하고 메시지를 전송한다.
  ///
  /// 공백만 있는 경우 무시하고, 유효한 텍스트가 있으면
  /// [ChatController.sendMessage]를 호출한 뒤 입력 필드를 초기화한다.
  void _submit(WidgetRef ref) {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      ref.read(chatControllerProvider.notifier).sendMessage(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  return TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _submit(ref),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Consumer(
              builder: (context, ref, child) {
                return IconButton(
                  onPressed: () => _submit(ref),
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).colorScheme.primary,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
