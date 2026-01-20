import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';

/// 채팅 세션 목록과 새 채팅 버튼을 제공하는 사이드바 위젯.
///
/// [chatSessionsProvider]를 구독하여 세션 목록을 표시하고,
/// [activeSessionIdProvider]로 현재 선택된 세션을 하이라이트한다.
/// "New Chat" 버튼 클릭 시 [ChatController.createNewSession]을 호출하고,
/// 세션 항목 클릭 시 해당 세션을 활성화한다.
///
/// 데스크탑에서는 화면 왼쪽에 고정 표시되고, 모바일에서는 [Drawer] 내부에 표시된다.
class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(chatSessionsProvider);
    final activeId = ref.watch(activeSessionIdProvider);

    return Container(
      width: 300,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(chatControllerProvider.notifier).createNewSession();
              },
              icon: const Icon(Icons.add),
              label: const Text('New Chat'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                final isActive = session.id == activeId;

                return ListTile(
                  title: Text(
                    session.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: isActive,
                  onTap: () {
                    ref.read(activeSessionIdProvider.notifier).set(session.id);
                  },
                  trailing: isActive
                      ? const Icon(Icons.chat_bubble_outline, size: 16)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
