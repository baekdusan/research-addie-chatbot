import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_session.dart';
import '../providers/chat_provider.dart';
import 'message_bubble.dart';
import 'chat_input.dart';

/// 활성 세션의 메시지와 입력 영역을 렌더링한다.
class ChatView extends ConsumerStatefulWidget {
  const ChatView({super.key});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 최신 메시지로 스크롤을 이동한다.
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(activeSessionProvider);

    // 메시지 목록 변경을 감지해 최신 메시지 또는 스트리밍 중인
    // 메시지로 자동 스크롤한다.
    ref.listen(activeSessionProvider, (previous, next) {
      if (next != null &&
          (previous == null ||
              next.messages.length > previous.messages.length ||
              (next.messages.isNotEmpty && next.messages.last.isStreaming))) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    return Column(
      children: [
        Expanded(
          child: session == null || session.messages.isEmpty
              ? _buildWelcome(context)
              : _buildMessageList(session),
        ),
        const ChatInput(),
      ],
    );
  }

  Widget _buildWelcome(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'How can I help you today?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(ChatSession session) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 20),
      itemCount: session.messages.length,
      itemBuilder: (context, index) {
        return MessageBubble(message: session.messages[index]);
      },
    );
  }
}
