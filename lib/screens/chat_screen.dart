import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/sidebar.dart';
import '../widgets/chat_view.dart';

/// 반응형 레이아웃을 제어하는 최상위 채팅 화면이다.
class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 900;

        return Scaffold(
          appBar: isLargeScreen
              ? null
              : AppBar(title: const Text('Ultrawork Chatbot')),
          drawer: isLargeScreen ? null : const Drawer(child: Sidebar()),
          body: Row(
            children: [
              if (isLargeScreen) const Sidebar(),
              const VerticalDivider(width: 1),
              const Expanded(child: ChatView()),
            ],
          ),
        );
      },
    );
  }
}
