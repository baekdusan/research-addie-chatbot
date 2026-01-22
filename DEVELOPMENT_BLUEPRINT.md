# ADDIE 기반 맞춤형 튜터링 챗봇 개발 청사진

## 1. 프로젝트 개요

### 1.1 연구 가설
> "어떠한 학습 주제든 ADDIE 프레임워크를 따르면 학습자 맞춤형 대화형 교육이 가능하다"

### 1.2 핵심 설계 원칙
- **주제 독립적(Topic-Agnostic)**: 특정 학습 주제에 종속되지 않는 범용 교수설계 엔진
- **Stateless Micro-Agent Pattern**: 앱이 상태를 보고 판단, LLM은 생성만
- **레이턴시 최적화**: 역할별 모델 분리, 단일 호출당 최소 토큰

### 1.3 아키텍처 진화

기존 LangGraph 기반 시스템에서 현재 구조로 전환한 이유:

| 항목 | 기존 (LangGraph) | 현재 (Micro-Agent) |
|------|-----------------|-------------------|
| 에이전트 구성 | 2개 (교수설계, 교사) | 6개 마이크로 서비스 |
| 상태 관리 | LLM 컨텍스트 내 | 외부 (Riverpod) |
| 판단 주체 | LLM | 앱 코드 |
| 프롬프트 크기 | 크고 복잡 | 작고 집중적 |
| 레이턴시 | ~30초/턴 | **2~5초/턴** |

---

## 2. 시스템 아키텍처

### 2.1 서비스 구성

```
┌─────────────────────────────────────────────────────────────┐
│                    App Orchestrator                         │
│              (ChatController + Riverpod State)              │
└─────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          ↓                   ↓                   ↓
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ IntentClassifier│ │ Conversational  │ │ SyllabusDesigner│
│    Service      │ │  AgentService   │ │    Service      │
├─────────────────┤ ├─────────────────┤ ├─────────────────┤
│ gemini-2.0-flash│ │ gemini-2.0/2.5  │ │gemini-3-flash   │
│ temp: 0.0       │ │ temp: 0.0~0.3   │ │ temp: 0.3       │
│ 분류만          │ │ 3가지 모드      │ │ 설계만          │
└─────────────────┘ └─────────────────┘ └─────────────────┘
                              │
               ┌──────────────┼──────────────┐
               ↓              ↓              ↓
         ┌──────────┐  ┌──────────┐  ┌──────────┐
         │ Analyst  │  │  Tutor   │  │ Feedback │
         │  모드    │  │  모드    │  │  모드    │
         └──────────┘  └──────────┘  └──────────┘
```

### 2.2 서비스별 역할 및 스펙

| 서비스 | 파일 | 역할 | 모델 | temp | 출력 스키마 |
|--------|------|------|------|------|------------|
| Intent Classifier | `intent_classifier_service.dart` | 수업 내/외 분류 | gemini-2.0-flash | 0.0 | `{intent}` |
| Analyst | `conversational_agent_service.dart` | 정보 수집 | gemini-2.0-flash | 0.0 | `{extracted_info, explicit_fields, response}` |
| Tutor (Streaming) | `gemini_service.dart` | 스트리밍 튜터링 | gemini-2.5-flash | - | Stream<String> |
| Tutor (JSON) | `conversational_agent_service.dart` | 비스트리밍 튜터링 | gemini-2.5-flash | 0.3 | `{response}` |
| Feedback | `conversational_agent_service.dart` | 피드백 처리 | gemini-2.0-flash | 0.3 | `{profile_update, response, needs_redesign, explicit_change, redesign_request}` |
| Syllabus Designer | `syllabus_designer_service.dart` | 커리큘럼 생성 | gemini-3-flash-preview | 0.3 | `{syllabus[]}` |
| Step Mapper | `step_mapper_service.dart` | 재설계 시 단계 매핑 | gemini-2.5-flash | 0.1 | `{mapped_step_index, confidence, reason}` |

---

## 3. State Hub 구조

### 3.1 LearningState (통합 상태)

```dart
class LearningState {
  final LearnerProfile learnerProfile;
  final InstructionalDesign instructionalDesign;
  final bool isDesigning;        // 설계 진행 중
  final bool showDesignReady;    // 설계 완료 알림 표시
  final bool isCourseCompleted;  // 학습 완료
  final DateTime updatedAt;
}
```

### 3.2 LearnerProfile (학습자 프로파일)

```dart
class LearnerProfile {
  final String? subject;           // 학습 주제 (필수)
  final String? goal;              // 학습 목표 (필수)
  final LearnerLevel? level;       // beginner/intermediate/expert
  final TonePreference? tonePreference;  // kind/formal/casual

  bool get isMandatoryFilled => subject != null && goal != null;
}
```

### 3.3 InstructionalDesign (교수설계)

```dart
class InstructionalDesign {
  final List<Step> syllabus;

  bool get designFilled => syllabus.isNotEmpty;
  int get totalSteps => syllabus.length;
}

class Step {
  final int step;        // 단계 번호 (1-based)
  final String topic;    // 소주제
  final String objective; // 학습 목표
}
```

### 3.4 상태 전이 조건

```
┌──────────────────────────────────────────────────────────────┐
│  isMandatoryFilled = subject != null && goal != null         │
│  designFilled = syllabus.isNotEmpty                          │
│  isReady = isMandatoryFilled && designFilled                 │
└──────────────────────────────────────────────────────────────┘

상태 전이:
  - 초기 상태: isMandatoryFilled=F, designFilled=F
  - 정보 수집 완료: isMandatoryFilled=T, designFilled=F → 설계 트리거
  - 설계 완료: isMandatoryFilled=T, designFilled=T → 수업 가능
  - 수업 완료: isCourseCompleted=T → 새 학습 시작 가능
```

---

## 4. 핵심 흐름 로직

### 4.1 ChatController.sendMessage() 분기

```dart
Future<void> sendMessage(String text) async {
  // 1. 설계 중이면 무시
  if (learning.isDesigning) return;

  // 2. 수업 완료 상태면 새 학습 시작 (Analyst)
  if (learning.isCourseCompleted) {
    await _runAnalystFlow(forceAnalyst: true);
    return;
  }

  // 3. 수업 준비 안됨
  final isReady = learning.learnerProfile.isMandatoryFilled &&
                  learning.instructionalDesign.designFilled;
  if (!isReady) {
    await _runAnalystFlow();
    return;
  }

  // 4. 수업 가능 상태 → 의도 분류
  final intent = await intentService.classify(text);
  if (intent == IntentResult.inClass) {
    await _runTutorFlow();  // 스트리밍
  } else {
    await _runFeedbackFlow();
  }
}
```

### 4.2 Analyst Flow

```dart
Future<void> _runAnalystFlow() async {
  // 1. 이미 준비됐으면 Feedback으로
  if (isMandatoryFilled && designFilled) {
    return _runFeedbackFlow();
  }

  // 2. 정보만 완성됐으면 설계 트리거
  if (isMandatoryFilled && !designFilled) {
    _startSyllabusDesign();
    return;
  }

  // 3. 정보 수집
  final result = await agent.runAnalyst(state, userText);
  _appendAssistantMessage(result.response);

  await updateFromExtractedInfo(
    subject: result.subject,
    goal: result.goal,
    level: result.level,
    tonePreference: result.tonePreference,
  );

  // 4. 정보 완성 시 설계 트리거
  if (updated.isMandatoryFilled && !updated.designFilled) {
    _startSyllabusDesign();
  }
}
```

### 4.3 Tutor Flow (스트리밍)

```dart
Future<void> _runTutorFlow() async {
  // 1. 프롬프트 생성 (로드맵 포함)
  final history = _buildHistory(limit: 6);
  final prompt = agent.buildTutorStreamingPrompt(state, userText, history);

  // 2. 빈 메시지 추가 (스트리밍용)
  final assistantId = Uuid().v4();
  _appendMessage(Message(id: assistantId, content: '', isStreaming: true));

  // 3. 스트리밍 수신
  final stream = gemini.streamResponse(messages, prompt);
  String fullResponse = '';
  await for (final chunk in stream) {
    fullResponse += chunk;
    // 메시지 업데이트
  }

  // 4. 스트리밍 완료 표시
  message.copyWith(isStreaming: false);
}
```

### 4.4 Feedback Flow

```dart
Future<void> _runFeedbackFlow() async {
  final result = await agent.runFeedback(state, userText);
  _appendAssistantMessage(result.response);

  // 명시적 변경 요청만 반영
  if (result.explicitChange) {
    await updateFromExtractedInfo(
      level: result.level,
      tonePreference: result.tonePreference,
    );
  }

  // 재설계 필요 시 (명시적 요청만)
  if (result.needsRedesign && result.explicitChange) {
    _startSyllabusDesign(
      isRedesign: true,
      redesignRequest: result.redesignRequest,
    );
  }
}
```

### 4.5 Syllabus Design (백그라운드)

```dart
void _startSyllabusDesign({bool isRedesign = false, String? redesignRequest}) {
  if (learning.isDesigning) return;

  await setDesigning(true);

  Future(() async {
    try {
      final syllabus = await designer.generate(
        learning.learnerProfile,
        redesignRequest: redesignRequest,
      );
      await setSyllabus(syllabus);

      // 설계 완료 후 자동으로 수업 시작
      await _runTutorFlow(sessionId, '수업을 시작해줘');
    } catch (e) {
      await setDesigning(false);
      _appendSystemMessage('로드맵 생성에 실패했어요.');
    }
  });
}
```

---

## 5. 프롬프트 설계

### 5.1 Intent Classifier

```
너는 학습자의 발화 의도를 분류하는 분류기다.
오직 분류만 수행하라. 정보 추출이나 답변 생성은 하지 마라.

[분류 규칙]
- out_of_class: 학습 주제, 목표, 수준, 말투, 순서 변경 등 '수업의 틀'을 바꾸는 발화
- in_class: 현재 진행 중인 수업 내용에 대한 발화

[중요]
- 애매하면 in_class로 분류하라. (default=in_class)
```

### 5.2 Analyst

```
너는 학습자의 정보를 수집하는 친절한 인터뷰어다.
자연스러운 대화를 통해 학습자의 학습 주제, 목표, 수준, 선호 말투를 파악하라.

[대화 원칙]
1) 한 번에 하나의 정보만 물어보라.
2) 이미 파악된 정보는 다시 묻지 마라.
3) 사용자가 명시적으로 언급하지 않은 값은 절대 추측하지 말고 null로 두어라.
4) 필수 정보(subject, goal)가 모두 파악되면 "로드맵을 만들겠다"고 안내하라.
```

### 5.3 Tutor (Streaming)

```
너는 학습자를 돕는 친절하고 전문적인 튜터다.
학습 로드맵을 참고하여 학습자의 흐름에 맞게 자연스럽게 수업을 진행하라.

[학습 로드맵]
{syllabusBlock}

[튜터링 원칙]
1) 정답을 먼저 말하지 마라. (비계 설정/Scaffolding)
2) 사용자가 어렵다고 하면 더 쉬운 설명으로 내려가라.
3) 이해 확인 질문은 필요할 때만 0~1개로 제한하라.
4) 로드맵을 참고하되, 대화 흐름에 따라 유연하게 진행하라.
5) 설명은 3~6문장 정도로 충분히 풀어라.

[출력 규칙]
- 반드시 한국어 자연어로만 답하라.
- JSON을 출력하지 마라.
```

### 5.4 Feedback

```
너는 학습자의 피드백을 수용하는 유연한 튜터다.

[피드백 처리 원칙]
1) 피드백을 긍정적으로 수용하라.
2) 난이도/말투 변경 요청은 profile_update에 반영하라.
3) 학습 경로 자체의 변경이 필요하면 needs_redesign=true로 설정하라.
4) 사용자가 명시적으로 요청한 경우에만 explicit_change=true로 설정하라.
5) 잡담/감정 표현이면 explicit_change=false로 두어라.
```

### 5.5 Syllabus Designer

```
너는 전문 교수설계자(Instructional Designer)다.
학습자의 프로필을 바탕으로 '주제'를 마스터하여 '목표'에 도달할 수 있는 커리큘럼을 설계하라.

[설계 원칙]
1) 단계는 1~5개로 구성하라.
2) 불필요하게 길게 늘어뜨리지 말고 목표 달성에 필요한 최소 단계만 제시하라.
3) 각 단계는 명확한 소주제(topic)와 구체적인 학습목표(objective)를 포함해야 한다.
4) level에 맞게 난이도를 조절하라.
5) 최종 단계는 goal과 직접 연결되어야 한다.
```

---

## 6. 출력 스키마 요약

| 서비스 | 출력 필드 |
|--------|----------|
| Intent Classifier | `intent` (in_class \| out_of_class) |
| Analyst | `extracted_info{subject?, goal?, level?, tone_preference?}`, `explicit_fields{}`, `response` |
| Tutor (JSON) | `response` |
| Feedback | `profile_update{level?, tone_preference?}`, `response`, `needs_redesign`, `explicit_change`, `redesign_request?` |
| Syllabus Designer | `syllabus[{step, topic, objective}]` |
| Step Mapper | `mapped_step_index`, `confidence`, `reason` |

---

## 7. 구현 현황

### Phase 1: State Hub 구축 ✅
- [x] State 모델 클래스 생성 (`LearnerProfile`, `InstructionalDesign`, `LearningState`)
- [x] State Provider 구현 (Riverpod)
- [x] State 영속화 (SharedPreferences)

### Phase 2: AI 서비스 분리 ✅
- [x] `IntentClassifierService` 구현
- [x] `ConversationalAgentService` 구현
  - [x] 분석가 모드
  - [x] 튜터 모드 (스트리밍)
  - [x] 피드백 모드
- [x] `SyllabusDesignerService` 구현
- [x] `StepMapperService` 구현

### Phase 3: 흐름 제어 로직 ✅
- [x] ChatController에 의도 분류 → 상태 체크 → 분기 로직 구현
- [x] 백그라운드 설계 프로세스 (비동기)
- [x] 상태 전이 트리거 구현

### Phase 4: UI 확장 (진행 중)
- [ ] 수업 계획 보기 모달/바텀시트
- [ ] 진도 표시 위젯
- [ ] 설계 중 로딩 인디케이터

### Phase 5: 평가 및 고도화 (예정)
- [ ] 피드백 기반 재설계 로직 개선
- [ ] 학습 완료 감지 로직

---

## 8. 기술 스택

| 영역 | 기술 |
|------|------|
| Framework | Flutter (Web) |
| State Management | Riverpod (코드 생성) |
| AI Backend | Firebase AI (Vertex AI) |
| Models | Gemini 2.0/2.5/3.0 Flash |
| Structured Output | Firebase AI responseSchema |
| Storage | SharedPreferences |

---

## 9. 핵심 설계 패턴

### 9.1 LLM as a Function
LLM을 순수 함수처럼 취급합니다. 입력(프롬프트 + 상태)을 받아 출력(JSON)을 반환하고, 상태 변경은 앱 코드에서 수행합니다.

```
f(prompt, state) → JSON → state update (by app code)
```

### 9.2 External State Management
상태를 LLM 컨텍스트가 아닌 외부(Riverpod)에서 관리합니다. 각 LLM 호출에 필요한 정보만 프롬프트에 주입합니다.

### 9.3 Application-Driven Orchestration
어떤 서비스를 호출할지는 앱 코드가 상태를 보고 결정합니다. LLM에게 판단을 위임하지 않습니다.

```dart
// 앱 코드가 판단
if (state.phase == analyzing) {
  return analystService.run(state, userText);
} else if (state.phase == tutoring) {
  return tutorService.run(state, userText);
}
```

### 9.4 Structured Output
모든 서비스는 JSON Schema를 사용하여 구조화된 출력을 반환합니다. 이를 통해 안정적인 파싱과 상태 업데이트가 가능합니다.

---

## 10. 연구적 시사점

### 논문에서의 프레이밍

> "본 연구의 시스템은 고정된 선형적 ADDIE 모델이 아니라, **State Hub를 중심으로 각 단계가 유기적으로 연결된 실시간 적응형 교수설계 엔진**을 지향한다. 이는 학습자의 모든 발화에 반응하여 교육과정을 실시간으로 재구성(Re-design)함으로써 진정한 개별화 학습을 가능케 한다."

### 핵심 학술 용어

- **Compound AI Systems**: 여러 AI 컴포넌트를 조합한 시스템 (Berkeley)
- **Multi-Agent Architecture**: 역할별로 분리된 에이전트 구조
- **Stateless Micro-Agent Pattern**: 앱이 오케스트레이션, LLM은 생성만
- **Dynamic Prompt Engineering**: 상태 기반 프롬프트 주입

---

*Last Updated: 2025-01-23*
*Version: 2.0*
