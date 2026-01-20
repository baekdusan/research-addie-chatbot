import 'package:flutter/material.dart';
import '../models/message.dart';

/// 단일 채팅 메시지를 말풍선 형태로 표시하는 위젯.
///
/// [Message.role]에 따라 스타일이 달라진다:
/// - **사용자 메시지**: 오른쪽 정렬, primary 색상 배경, 사람 아이콘
/// - **AI 메시지**: 왼쪽 정렬, surfaceVariant 색상 배경, 로봇 아이콘
///
/// 말풍선 모서리는 발신자 방향의 하단만 각지게 처리하여 대화 흐름을 시각적으로 표현한다.
class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(context),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12).copyWith(
                  bottomRight: isUser ? const Radius.circular(0) : null,
                  bottomLeft: !isUser ? const Radius.circular(0) : null,
                ),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) _buildAvatar(context),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    return CircleAvatar(
      backgroundColor: isUser
          ? Theme.of(context).colorScheme.secondary
          : Theme.of(context).colorScheme.tertiary,
      radius: 16,
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        size: 16,
        color: Colors.white,
      ),
    );
  }
}
