import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_session.dart';
import '../models/message.dart';
import '../services/gemini_service.dart';

part 'chat_provider.g.dart';

/// 앱 전역에서 공유하는 Gemini 서비스 인스턴스다.
@Riverpod(keepAlive: true)
GeminiService geminiService(GeminiServiceRef ref) {
  return GeminiService();
}

/// 히스토리와 탐색을 위해 모든 세션을 보관한다.
@riverpod
class ChatSessions extends _$ChatSessions {
  @override
  List<ChatSession> build() {
    return [];
  }

  /// 새로운 세션을 추가한다.
  void addSession(ChatSession session) {
    state = [...state, session];
  }

  /// id 기준으로 기존 세션을 교체한다.
  void updateSession(ChatSession session) {
    state = [
      for (final s in state)
        if (s.id == session.id) session else s,
    ];
  }

  /// id 기준으로 세션을 삭제한다.
  void deleteSession(String id) {
    state = state.where((s) => s.id != id).toList();
  }
}

/// 현재 UI에서 활성화된 세션 id를 관리한다.
@riverpod
class ActiveSessionId extends _$ActiveSessionId {
  @override
  String? build() {
    return null;
  }

  /// 활성 세션 id를 설정한다. 새 세션 시작 시 null로 초기화한다.
  void set(String? id) {
    state = id;
  }
}

/// 현재 활성 세션을 반환하는 파생 프로바이더다.
@riverpod
ChatSession? activeSession(ActiveSessionRef ref) {
  final sessions = ref.watch(chatSessionsProvider);
  final activeId = ref.watch(activeSessionIdProvider);
  if (activeId == null) return null;
  return sessions.firstWhere((s) => s.id == activeId);
}

/// 메시지 송수신과 스트리밍 업데이트 흐름을 총괄한다.
@riverpod
class ChatController extends _$ChatController {
  @override
  FutureOr<void> build() {
    // Nothing to initialize
  }

  /// 사용자 메시지를 전송하고, 어시스턴트 응답을 스트리밍한다.
  ///
  /// 처리 흐름:
  /// 1) 세션 존재 여부 확인
  /// 2) 사용자 메시지 추가
  /// 3) 스트리밍용 어시스턴트 메시지 자리표시 추가
  /// 4) 스트림을 받아 자리표시를 갱신
  /// 5) 스트리밍 완료 처리
  Future<void> sendMessage(String text) async {
    final activeId = ref.read(activeSessionIdProvider);
    final sessions = ref.read(chatSessionsProvider);

    ChatSession? session;
    if (activeId == null) {
      // 활성 세션이 없으면 새 세션을 만든다.
      session = ChatSession(
        title: text.length > 20 ? '${text.substring(0, 20)}...' : text,
      );
      ref.read(chatSessionsProvider.notifier).addSession(session);
      ref.read(activeSessionIdProvider.notifier).set(session.id);
    } else {
      session = sessions.firstWhere((s) => s.id == activeId);
    }

    // 사용자 메시지를 추가한다.
    final userMessage = Message(role: MessageRole.user, content: text);
    final updatedMessages = [...session.messages, userMessage];
    session = session.copyWith(messages: updatedMessages);
    ref.read(chatSessionsProvider.notifier).updateSession(session);

    // 스트리밍 업데이트용 어시스턴트 메시지 자리표시를 만든다.
    final assistantId = const Uuid().v4();
    final assistantMessage = Message(
      id: assistantId,
      role: MessageRole.model,
      content: '',
      isStreaming: true,
    );

    session = session.copyWith(
      messages: [...session.messages, assistantMessage],
    );
    ref.read(chatSessionsProvider.notifier).updateSession(session);

    // Gemini 스트리밍 API를 호출한다.
    final gemini = ref.read(geminiServiceProvider);

    try {
      final stream = gemini.streamResponse(
        session.messages.where((m) => m.id != assistantId).toList(),
        text,
      );

      String fullResponse = '';
      await for (final chunk in stream) {
        fullResponse += chunk;

        // 부분 응답을 누적해 세션 메시지를 갱신한다.
        final currentSessions = ref.read(chatSessionsProvider);
        final currentSession = currentSessions.firstWhere(
          (s) => s.id == session!.id,
        );

        final newMessages = [
          for (final m in currentSession.messages)
            if (m.id == assistantId) m.copyWith(content: fullResponse) else m,
        ];

        ref
            .read(chatSessionsProvider.notifier)
            .updateSession(currentSession.copyWith(messages: newMessages));
      }

      // 스트리밍 완료 상태로 변경한다.
      final finalSessions = ref.read(chatSessionsProvider);
      final finalSession = finalSessions.firstWhere((s) => s.id == session!.id);
      final finalMessages = [
        for (final m in finalSession.messages)
          if (m.id == assistantId) m.copyWith(isStreaming: false) else m,
      ];
      ref
          .read(chatSessionsProvider.notifier)
          .updateSession(finalSession.copyWith(messages: finalMessages));
    } catch (e) {
      // 에러 발생 시 자리표시 메시지에 오류를 기록한다.
      final errorSessions = ref.read(chatSessionsProvider);
      final errorSession = errorSessions.firstWhere((s) => s.id == session!.id);
      final errorMessages = [
        for (final m in errorSession.messages)
          if (m.id == assistantId)
            m.copyWith(content: 'Error: $e', isStreaming: false)
          else
            m,
      ];
      ref
          .read(chatSessionsProvider.notifier)
          .updateSession(errorSession.copyWith(messages: errorMessages));
    }
  }

  /// 활성 세션을 비워 새 대화를 시작한다.
  void createNewSession() {
    ref.read(activeSessionIdProvider.notifier).set(null);
  }
}
