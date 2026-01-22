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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[_buildAvatar(context), const SizedBox(width: 12)],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
              ),
              child: Text(
                message.content,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isUser
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      radius: 16,
      child: Icon(
        Icons.smart_toy_outlined,
        size: 18,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
