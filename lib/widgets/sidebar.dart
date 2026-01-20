import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';

/// 세션 목록을 표시하고 새 세션을 만들 수 있게 한다.
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
