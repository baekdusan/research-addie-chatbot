import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_session.dart';
import '../models/message.dart';
import '../services/gemini_service.dart';

part 'chat_provider.g.dart';

/// [GeminiService]의 싱글톤 인스턴스를 제공하는 프로바이더.
///
/// `keepAlive: true` 설정으로 앱 생명주기 동안 인스턴스가 유지되어
/// 불필요한 재생성을 방지하고 연결 상태를 보존한다.
@Riverpod(keepAlive: true)
GeminiService geminiService(GeminiServiceRef ref) {
  return GeminiService();
}

/// 앱의 모든 채팅 세션을 관리하는 상태 노티파이어.
///
/// 세션 목록을 [List<ChatSession>]으로 보관하며 추가, 수정, 삭제 기능을 제공한다.
/// [Sidebar]의 세션 히스토리 표시와 세션 전환에 사용된다.
@riverpod
class ChatSessions extends _$ChatSessions {
  @override
  List<ChatSession> build() {
    return [];
  }

  /// 새 [ChatSession]을 세션 목록에 추가한다.
  ///
  /// 첫 메시지 전송 시 [ChatController.sendMessage]에서 자동 호출되어 새 대화를 시작한다.
  void addSession(ChatSession session) {
    state = [...state, session];
  }

  /// 동일한 ID를 가진 세션을 찾아 새 세션으로 교체한다.
  ///
  /// 메시지 추가, 제목 변경 등 세션 내용이 업데이트될 때마다 호출된다.
  /// 불변성을 유지하기 위해 기존 세션을 수정하지 않고 새 객체로 대체한다.
  void updateSession(ChatSession session) {
    state = [
      for (final s in state)
        if (s.id == session.id) session else s,
    ];
  }

  /// 지정된 ID의 세션을 목록에서 제거한다.
  ///
  /// 사용자가 사이드바에서 대화 기록을 삭제할 때 호출된다.
  void deleteSession(String id) {
    state = state.where((s) => s.id != id).toList();
  }
}

/// 현재 화면에 표시 중인 채팅 세션의 ID를 추적하는 상태 노티파이어.
///
/// null이면 아직 세션이 선택되지 않은 상태이며,
/// 첫 메시지 전송 시 새 세션이 자동 생성된다.
@riverpod
class ActiveSessionId extends _$ActiveSessionId {
  @override
  String? build() {
    return null;
  }

  /// 활성 세션 ID를 변경한다.
  ///
  /// [Sidebar]에서 세션 클릭 시 해당 ID로 설정되고,
  /// "New Chat" 버튼 클릭 시 null로 초기화되어 새 대화 준비 상태가 된다.
  void set(String? id) {
    state = id;
  }
}

/// [activeSessionIdProvider]와 [chatSessionsProvider]를 조합하여 현재 활성화된 [ChatSession] 객체를 반환하는 파생(computed) 프로바이더.
///
/// UI에서 현재 대화 내용을 표시할 때 `ref.watch`로 구독하며,
/// 활성 ID가 없거나 해당 세션이 없으면 null을 반환한다.
@riverpod
ChatSession? activeSession(ActiveSessionRef ref) {
  final sessions = ref.watch(chatSessionsProvider);
  final activeId = ref.watch(activeSessionIdProvider);
  if (activeId == null) return null;
  return sessions.firstWhere((s) => s.id == activeId);
}

/// 채팅의 핵심 비즈니스 로직을 담당하는 컨트롤러.
///
/// 사용자 메시지 전송, AI 응답 스트리밍 수신, 세션 상태 업데이트를 조율한다.
/// [ChatInput]에서 메시지 전송 시, [Sidebar]에서 새 채팅 생성 시 호출된다.
@riverpod
class ChatController extends _$ChatController {
  @override
  FutureOr<void> build() {
    // Nothing to initialize
  }

  /// 사용자 메시지를 처리하고 AI 응답을 스트리밍으로 수신하는 메인 메서드.
  ///
  /// 세부 처리 흐름:
  /// 1. 활성 세션이 없으면 새 [ChatSession]을 자동 생성하고 제목을 첫 메시지로 설정
  /// 2. 사용자 메시지([MessageRole.user])를 세션에 추가
  /// 3. AI 응답을 담을 빈 플레이스홀더 메시지를 `isStreaming: true`로 추가
  /// 4. [GeminiService.streamResponse]에서 텍스트 청크가 도착할 때마다 플레이스홀더 내용을 누적 업데이트
  /// 5. 스트림 종료 시 `isStreaming: false`로 변경하여 완료 상태로 전환
  ///
  /// 에러 발생 시 플레이스홀더 메시지에 오류 내용을 표시한다.
  Future<void> sendMessage(String text) async {
    final activeId = ref.read(activeSessionIdProvider);
    final sessions = ref.read(chatSessionsProvider);

    ChatSession? session;
    if (activeId == null) {
      // 활성 세션이 없으면 새 세션을 생성하고, 첫 메시지 앞부분을 제목으로 사용한다.
      session = ChatSession(
        title: text.length > 20 ? '${text.substring(0, 20)}...' : text,
      );
      ref.read(chatSessionsProvider.notifier).addSession(session);
      ref.read(activeSessionIdProvider.notifier).set(session.id);
    } else {
      session = sessions.firstWhere((s) => s.id == activeId);
    }

    // 사용자 메시지를 생성하여 현재 세션의 메시지 목록에 추가한다.
    final userMessage = Message(role: MessageRole.user, content: text);
    final updatedMessages = [...session.messages, userMessage];
    session = session.copyWith(messages: updatedMessages);
    ref.read(chatSessionsProvider.notifier).updateSession(session);

    // AI 응답을 담을 빈 플레이스홀더 메시지를 생성한다. isStreaming=true로 설정하여 UI에서 로딩 상태를 표시할 수 있다.
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

    // Gemini API에 대화 기록과 함께 스트리밍 요청을 보낸다.
    final gemini = ref.read(geminiServiceProvider);

    try {
      final stream = gemini.streamResponse(
        session.messages.where((m) => m.id != assistantId).toList(),
        text,
      );

      String fullResponse = '';
      await for (final chunk in stream) {
        fullResponse += chunk;

        // 도착한 청크를 누적하여 플레이스홀더 메시지 내용을 실시간 업데이트한다.
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

      // 스트림이 종료되면 isStreaming을 false로 변경하여 완료 상태를 표시한다.
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
      // 에러 발생 시 플레이스홀더 메시지에 오류 내용을 표시하고 스트리밍을 종료한다.
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

  /// 활성 세션 ID를 null로 초기화하여 새 대화를 시작할 준비를 한다.
  ///
  /// [Sidebar]의 "New Chat" 버튼 클릭 시 호출되며,
  /// 다음 메시지 전송 시 새 세션이 자동 생성된다.
  void createNewSession() {
    ref.read(activeSessionIdProvider.notifier).set(null);
  }
}
