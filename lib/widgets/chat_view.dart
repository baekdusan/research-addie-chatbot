import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_session.dart';
import '../providers/chat_provider.dart';
import '../providers/learning_state_provider.dart';
import '../models/instructional_design.dart' as id;
import '../models/learning_state.dart';
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
    final learningState = ref.watch(learningStateNotifierProvider);

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
        if (learningState.instructionalDesign.syllabus.isNotEmpty)
          _buildSyllabusHeader(context, learningState.instructionalDesign),
        _buildStatusBanner(context, learningState),
        Expanded(
          child: session == null || session.messages.isEmpty
              ? _buildWelcome(context)
              : _buildMessageList(session),
        ),
        const ChatInput(),
      ],
    );
  }

  Widget _buildStatusBanner(BuildContext context, LearningState state) {
    if (!state.isDesigning && !state.showDesignReady) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDesigning = state.isDesigning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: isDesigning
            ? theme.colorScheme.surfaceContainer
            : theme.colorScheme.tertiaryContainer.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: isDesigning
                ? theme.colorScheme.outlineVariant
                : theme.colorScheme.tertiary.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isDesigning)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                else
                  Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: theme.colorScheme.tertiary,
                  ),
                const SizedBox(width: 8),
                Text(
                  isDesigning ? '로드맵 생성 중...' : '로드맵 준비 완료',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDesigning
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.tertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyllabusHeader(
    BuildContext context,
    id.InstructionalDesign design,
  ) {
    final theme = Theme.of(context);
    final totalSteps = design.syllabus.length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '학습 로드맵 ($totalSteps단계)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showSyllabusModal(context, design),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.list_alt, size: 16),
                  label: const Text('목차 보기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSyllabusModal(BuildContext context, id.InstructionalDesign design) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.map,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '학습 로드맵',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: design.syllabus.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final step = design.syllabus[index];
                      final theme = Theme.of(context);

                      return Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            foregroundColor: theme.colorScheme.onSurfaceVariant,
                            child: Text(
                              '${step.step}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            step.topic,
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              step.objective,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildWelcome(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
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
      ),
    );
  }

  Widget _buildMessageList(ChatSession session) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 20),
      itemCount: session.messages.length,
      itemBuilder: (context, index) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: MessageBubble(message: session.messages[index]),
          ),
        );
      },
    );
  }
}
