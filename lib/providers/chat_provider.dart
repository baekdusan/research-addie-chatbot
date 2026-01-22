import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/chat_session.dart';
import '../models/message.dart';
import '../models/learning_state.dart';
import '../providers/learning_state_provider.dart';
import '../services/gemini_service.dart';
import '../services/intent_classifier_service.dart';
import '../services/conversational_agent_service.dart';
import '../services/syllabus_designer_service.dart';

part 'chat_provider.g.dart';

/// [GeminiService]의 싱글톤 인스턴스를 제공하는 프로바이더.
///
/// `keepAlive: true` 설정으로 앱 생명주기 동안 인스턴스가 유지되어
/// 불필요한 재생성을 방지하고 연결 상태를 보존한다.
@Riverpod(keepAlive: true)
GeminiService geminiService(GeminiServiceRef ref) {
  return GeminiService();
}

@Riverpod(keepAlive: true)
IntentClassifierService intentClassifierService(
  IntentClassifierServiceRef ref,
) {
  return IntentClassifierService();
}

@Riverpod(keepAlive: true)
ConversationalAgentService conversationalAgentService(
  ConversationalAgentServiceRef ref,
) {
  return ConversationalAgentService();
}

@Riverpod(keepAlive: true)
SyllabusDesignerService syllabusDesignerService(
  SyllabusDesignerServiceRef ref,
) {
  return SyllabusDesignerService();
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
@Riverpod(keepAlive: true)
class ChatController extends _$ChatController {
  int _turnCounter = 0;
  @override
  FutureOr<void> build() {
    // Nothing to initialize
  }

  /// 사용자 메시지를 처리하고 상태 기반 의사결정을 수행하는 메인 메서드.
  Future<void> sendMessage(String text) async {
    _turnCounter += 1;
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

    _appendMessage(session.id, Message(role: MessageRole.user, content: text));

    final learning = ref.read(learningStateNotifierProvider);
    _log('turn.start', {
      'turn': _turnCounter,
      'text': text,
      'mandatory': learning.learnerProfile.isMandatoryFilled,
      'designFilled': learning.instructionalDesign.designFilled,
      'designing': learning.isDesigning,
      'designReady': learning.showDesignReady,
      'completed': learning.isCourseCompleted,
      'subject': learning.learnerProfile.subject,
      'goal': learning.learnerProfile.goal,
      'totalSteps': learning.instructionalDesign.totalSteps,
    });
    if (learning.isDesigning) {
      return;
    }

    if (learning.isCourseCompleted) {
      await _runAnalystFlow(session.id, text, learning, forceAnalyst: true);
      return;
    }

    final isReady = learning.learnerProfile.isMandatoryFilled &&
        learning.instructionalDesign.designFilled;
    if (!isReady) {
      await _runAnalystFlow(session.id, text, learning);
      return;
    }

    final intentService = ref.read(intentClassifierServiceProvider);
    final intent = await intentService.classify(text);
    _log('intent', {
      'turn': _turnCounter,
      'value': intent.name,
    });

    if (intent == IntentResult.inClass) {
      await _runTutorFlow(session.id, text);
    } else {
      await _runFeedbackFlow(session.id, text);
    }
  }

  /// 활성 세션 ID를 null로 초기화하여 새 대화를 시작할 준비를 한다.
  ///
  /// [Sidebar]의 "New Chat" 버튼 클릭 시 호출되며,
  /// 다음 메시지 전송 시 새 세션이 자동 생성된다.
  void createNewSession() {
    ref.read(activeSessionIdProvider.notifier).set(null);
  }

  Future<void> _runAnalystFlow(
    String sessionId,
    String userText,
    LearningState previous, {
    bool forceAnalyst = false,
  }) async {
    if (!forceAnalyst &&
        previous.learnerProfile.isMandatoryFilled &&
        previous.instructionalDesign.designFilled) {
      await _runFeedbackFlow(sessionId, userText);
      return;
    }

    if (!forceAnalyst &&
        previous.learnerProfile.isMandatoryFilled &&
        !previous.instructionalDesign.designFilled) {
      _startSyllabusDesign(sessionId, isRedesign: false);
      return;
    }

    final agent = ref.read(conversationalAgentServiceProvider);
    try {
      final result = await agent.runAnalyst(previous, userText);
      _log('analyst.extract', {
        'turn': _turnCounter,
        'subject': result.subject,
        'goal': result.goal,
        'level': result.level?.name,
        'tone': result.tonePreference?.name,
      });
      _appendAssistantMessage(sessionId, result.response);

      await ref
          .read(learningStateNotifierProvider.notifier)
          .updateFromExtractedInfo(
            subject: result.subject,
            goal: result.goal,
            level: result.level,
            tonePreference: result.tonePreference,
          );

      final updated = ref.read(learningStateNotifierProvider);
      final wasMandatory = previous.learnerProfile.isMandatoryFilled;
      final shouldTriggerDesign =
          updated.learnerProfile.isMandatoryFilled &&
          !updated.instructionalDesign.designFilled &&
          (forceAnalyst || !wasMandatory);
      if (shouldTriggerDesign) {
        _startSyllabusDesign(sessionId, isRedesign: false);
      }
    } catch (e) {
      _appendSystemMessage(sessionId, '요청을 처리하는 중 오류가 발생했어요. 다시 시도해 주세요.');
    }
  }

  Future<void> _runTutorFlow(String sessionId, String userText) async {
    final learning = ref.read(learningStateNotifierProvider);
    final agent = ref.read(conversationalAgentServiceProvider);
    String? assistantId;
    try {
      final history = _buildHistory(sessionId, userText, limit: 6);
      final prompt = agent.buildTutorStreamingPrompt(learning, userText, history);
      assistantId = const Uuid().v4();
      _appendMessage(
        sessionId,
        Message(
          id: assistantId,
          role: MessageRole.model,
          content: '',
          isStreaming: true,
        ),
      );

      final gemini = ref.read(geminiServiceProvider);
      final session = ref.read(chatSessionsProvider).firstWhere(
            (s) => s.id == sessionId,
          );
      final stream = gemini.streamResponse(
        session.messages.where((m) => m.id != assistantId).toList(),
        prompt,
      );

      String fullResponse = '';
      await for (final chunk in stream) {
        fullResponse += chunk;
        final currentSessions = ref.read(chatSessionsProvider);
        final currentSession = currentSessions.firstWhere(
          (s) => s.id == sessionId,
        );
        final newMessages = [
          for (final m in currentSession.messages)
            if (m.id == assistantId) m.copyWith(content: fullResponse) else m,
        ];
        ref
            .read(chatSessionsProvider.notifier)
            .updateSession(currentSession.copyWith(messages: newMessages));
      }

      final finalSessions = ref.read(chatSessionsProvider);
      final finalSession = finalSessions.firstWhere((s) => s.id == sessionId);
      final finalMessages = [
        for (final m in finalSession.messages)
          if (m.id == assistantId) m.copyWith(isStreaming: false) else m,
      ];
      ref
          .read(chatSessionsProvider.notifier)
          .updateSession(finalSession.copyWith(messages: finalMessages));

      final latest = ref.read(learningStateNotifierProvider);
      if (latest.showDesignReady) {
        await ref.read(learningStateNotifierProvider.notifier).setDesignReady(false);
      }
    } catch (e) {
      if (assistantId != null) {
        final sessions = ref.read(chatSessionsProvider);
        final session = sessions.firstWhere((s) => s.id == sessionId);
        final updatedMessages = [
          for (final m in session.messages)
            if (m.id == assistantId)
              m.copyWith(
                content: '응답 생성 중 오류가 발생했어요. 다시 시도해 주세요.',
                isStreaming: false,
              )
            else
              m,
        ];
        ref
            .read(chatSessionsProvider.notifier)
            .updateSession(session.copyWith(messages: updatedMessages));
      } else {
        _appendSystemMessage(sessionId, '튜터 응답을 생성하는 중 오류가 발생했어요.');
      }
    }
  }

  Future<void> _runFeedbackFlow(String sessionId, String userText) async {
    final learning = ref.read(learningStateNotifierProvider);
    final agent = ref.read(conversationalAgentServiceProvider);
    try {
      final result = await agent.runFeedback(learning, userText);
      _appendAssistantMessage(sessionId, result.response);
      _log('feedback.result', {
        'turn': _turnCounter,
        'needsRedesign': result.needsRedesign,
        'explicitChange': result.explicitChange,
        'redesignRequest': result.redesignRequest,
      });

      if (result.explicitChange) {
        await ref
            .read(learningStateNotifierProvider.notifier)
            .updateFromExtractedInfo(
              level: result.level,
              tonePreference: result.tonePreference,
            );
      }

      if (result.needsRedesign && result.explicitChange) {
        _startSyllabusDesign(
          sessionId,
          isRedesign: true,
          redesignRequest: result.redesignRequest,
        );
      } else if (result.needsRedesign && !result.explicitChange) {
        _log('feedback.ignored_redesign', {'reason': 'not_explicit'});
      }
    } catch (e) {
      _appendSystemMessage(sessionId, '피드백을 처리하는 중 오류가 발생했어요.');
    }
  }

  void _startSyllabusDesign(
    String sessionId, {
    required bool isRedesign,
    String? redesignRequest,
  }) {
    final learning = ref.read(learningStateNotifierProvider);
    if (learning.isDesigning) return;

    _log('design.start', {
      'turn': _turnCounter,
      'isRedesign': isRedesign,
      'request': redesignRequest,
    });
    unawaited(ref.read(learningStateNotifierProvider.notifier).setDesigning(true));

    Future(() async {
      try {
        final designer = ref.read(syllabusDesignerServiceProvider);
        final syllabus = await designer.generate(
          learning.learnerProfile,
          redesignRequest: redesignRequest,
        );
        _log('design.generated', {
          'turn': _turnCounter,
          'steps': syllabus.length,
          'topics': syllabus.map((step) => step.topic).toList(),
        });

        await ref
            .read(learningStateNotifierProvider.notifier)
            .setSyllabus(syllabus);
        await _runTutorFlow(sessionId, '수업을 시작해줘');
      } catch (e) {
        _log('design.error', {'error': e.toString()});
        await ref
            .read(learningStateNotifierProvider.notifier)
            .setDesigning(false);
        _appendSystemMessage(sessionId, '로드맵 생성에 실패했어요. 잠시 후 다시 시도해 주세요.');
      }
    });
  }

  void _appendAssistantMessage(String sessionId, String content) {
    _appendMessage(sessionId, Message(role: MessageRole.model, content: content));
  }

  void _appendSystemMessage(String sessionId, String content) {
    _appendMessage(sessionId, Message(role: MessageRole.system, content: content));
  }

  void _appendMessage(String sessionId, Message message) {
    final sessions = ref.read(chatSessionsProvider);
    final session = sessions.firstWhere((s) => s.id == sessionId);
    final updatedMessages = [...session.messages, message];
    ref
        .read(chatSessionsProvider.notifier)
        .updateSession(session.copyWith(messages: updatedMessages));
  }

  List<String> _buildHistory(
    String sessionId,
    String currentUserText, {
    int limit = 6,
  }) {
    final session = ref.read(chatSessionsProvider).firstWhere(
          (s) => s.id == sessionId,
        );
    final filtered = session.messages
        .where((m) => m.role != MessageRole.system)
        .toList();
    if (filtered.isNotEmpty &&
        filtered.last.role == MessageRole.user &&
        filtered.last.content == currentUserText) {
      filtered.removeLast();
    }
    final recent = filtered.length > limit
        ? filtered.sublist(filtered.length - limit)
        : filtered;
    return recent
        .map((m) =>
            m.role == MessageRole.user ? 'User: ${m.content}' : 'Tutor: ${m.content}')
        .toList();
  }


  void _log(String event, Map<String, dynamic> data) {
    final payload = jsonEncode(data);
    debugPrint('[Flow] $event $payload');
  }
}
