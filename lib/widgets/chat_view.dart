import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_session.dart';
import '../providers/chat_provider.dart';
import 'message_bubble.dart';
import 'chat_input.dart';

/// 현재 활성화된 채팅 세션의 메시지 목록과 입력 영역을 렌더링하는 메인 뷰 위젯.
///
/// [activeSessionProvider]를 구독하여 메시지가 변경될 때마다 UI를 업데이트한다.
/// 세션이 없거나 메시지가 비어있으면 환영 화면을 표시하고,
/// 그렇지 않으면 [MessageBubble] 리스트와 [ChatInput]을 표시한다.
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

  /// 메시지 목록을 최하단으로 애니메이션 스크롤한다.
  ///
  /// 새 메시지가 추가되거나 스트리밍 중일 때 호출되어
  /// 사용자가 항상 최신 메시지를 볼 수 있도록 한다.
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

    // activeSessionProvider 변경을 감지하여 자동 스크롤을 트리거한다.
    // 새 메시지가 추가되거나 마지막 메시지가 스트리밍 중이면 하단으로 스크롤한다.
    // addPostFrameCallback을 사용하여 프레임 렌더링 완료 후 스크롤을 실행한다.
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
