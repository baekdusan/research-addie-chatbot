# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ADDIE 모델 기반 적응형 학습 튜터 시스템. Flutter Web + Firebase AI (Vertex AI) + Riverpod 상태 관리를 사용합니다.

### Core Architecture: Stateless Micro-Agent Pattern

이 프로젝트는 **"LLM이 판단"하는 Fat Agent 방식이 아닌, "앱이 판단하고 LLM은 생성만"하는 Thin Micro-Services 패턴**을 사용합니다.

```
App Orchestrator (ChatController)
    ↓ 상태 기반 라우팅
┌───────────┬──────────────┬─────────────┬────────────┐
│ Intent    │ Conversational│ Syllabus   │ Step      │
│ Classifier│ AgentService │ Designer   │ Mapper    │
│ (분류만)  │ (3가지 모드)  │ (설계)     │ (매핑)    │
└───────────┴──────────────┴─────────────┴────────────┘
```

---

## Common Commands

```bash
# Run the app
flutter run -d chrome

# Build for web
flutter build web

# Run tests
flutter test

# Analyze code
flutter analyze

# Install dependencies
flutter pub get

# Code generation (required after adding @riverpod annotations)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode for code generation
flutter pub run build_runner watch
```

---

## Directory Structure

```
lib/
├── models/                          # 데이터 모델
│   ├── message.dart                 # 채팅 메시지
│   ├── chat_session.dart            # 채팅 세션
│   ├── learner_profile.dart         # 학습자 프로파일 (subject, goal, level, tone)
│   ├── instructional_design.dart    # 교수설계 (Step, Syllabus)
│   └── learning_state.dart          # 통합 학습 상태
│
├── providers/
│   ├── chat_provider.dart           # ⭐ 핵심 오케스트레이션 로직
│   ├── chat_provider.g.dart         # (generated - do not edit)
│   ├── learning_state_provider.dart # 학습 상태 관리 + 영속화
│   └── learning_state_provider.g.dart # (generated)
│
├── services/                        # ⭐ Micro-Agent Services
│   ├── gemini_service.dart          # 스트리밍 응답 (Tutor용)
│   ├── intent_classifier_service.dart  # 의도 분류 (in/out class)
│   ├── conversational_agent_service.dart # Analyst/Tutor/Feedback 모드
│   ├── syllabus_designer_service.dart   # 커리큘럼 생성
│   └── step_mapper_service.dart     # 재설계 시 단계 매핑
│
├── screens/
│   └── chat_screen.dart             # 메인 화면 (반응형: 900px 기준)
│
└── widgets/
    ├── chat_view.dart               # 채팅 메시지 표시
    ├── chat_input.dart              # 입력 위젯
    ├── message_bubble.dart          # 메시지 버블
    └── sidebar.dart                 # 세션 사이드바
```

---

## Core Data Flow

### 1. 메시지 처리 흐름 (ChatController.sendMessage)

```dart
// 1. 상태 체크
if (isDesigning) return;  // 설계 중이면 대기
if (isCourseCompleted) → _runAnalystFlow()  // 완료 후 새 학습

// 2. 프로파일/설계 미완성 시
if (!isMandatoryFilled || !designFilled) → _runAnalystFlow()

// 3. 수업 가능 상태
intent = await intentClassifier.classify(text)
if (intent == inClass) → _runTutorFlow()   // 스트리밍
else → _runFeedbackFlow()                   // 피드백 처리
```

### 2. 서비스별 역할

| Service | 역할 | 모델 | 출력 형식 |
|---------|------|------|----------|
| `IntentClassifierService` | 수업 내/외 분류 | gemini-2.0-flash | `{intent}` |
| `ConversationalAgentService.runAnalyst` | 정보 수집 | gemini-2.0-flash | `{extracted_info, response}` |
| `ConversationalAgentService.runTutor` | 튜터링 (비스트리밍) | gemini-2.5-flash | `{response}` |
| `ConversationalAgentService.buildTutorStreamingPrompt` | 튜터링 프롬프트 생성 | - | String |
| `ConversationalAgentService.runFeedback` | 피드백 처리 | gemini-2.0-flash | `{profile_update, response, needs_redesign}` |
| `SyllabusDesignerService` | 커리큘럼 생성 | gemini-3-flash-preview | `{syllabus[]}` |
| `StepMapperService` | 단계 매핑 | gemini-2.5-flash | `{mapped_step_index, confidence}` |
| `GeminiService` | 스트리밍 응답 | gemini-2.5-flash | Stream<String> |

---

## Key Patterns

### Riverpod Providers

```dart
// Singleton services
@Riverpod(keepAlive: true)
GeminiService geminiService(ref) => GeminiService();

// State notifiers
@riverpod
class LearningStateNotifier extends _$LearningStateNotifier { ... }

// Computed state
@riverpod
ChatSession? activeSession(ref) { ... }
```

### Model Conventions

- Immutable with `copyWith()` methods
- `toJson()`/`fromJson()` factories for serialization
- `isMandatoryFilled`, `designFilled` 등 computed getters

### State Management

- `LearningState`: 통합 학습 상태 (profile + design + flags)
- `SharedPreferences`: 로컬 영속화
- 상태 변경 시 항상 `_saveToPrefs()` 호출

---

## Important Implementation Details

### 1. Tutor 스트리밍

Tutor 모드는 `GeminiService.streamResponse()`를 사용하여 실시간 스트리밍합니다:

```dart
// chat_provider.dart - _runTutorFlow()
final prompt = agent.buildTutorStreamingPrompt(learning, userText, history);
final stream = gemini.streamResponse(messages, prompt);
await for (final chunk in stream) {
  // 메시지 업데이트
}
```

### 2. Syllabus 생성 (백그라운드)

설계는 비동기로 실행되며, 완료 시 자동으로 수업을 시작합니다:

```dart
// chat_provider.dart - _startSyllabusDesign()
await setDesigning(true);
Future(() async {
  final syllabus = await designer.generate(profile);
  await setSyllabus(syllabus);
  await _runTutorFlow(sessionId, '수업을 시작해줘');
});
```

### 3. 상태 전이 조건

```
isMandatoryFilled = subject != null && goal != null
designFilled = syllabus.isNotEmpty
isReady = isMandatoryFilled && designFilled
```

---

## Firebase AI Configuration

All services use `FirebaseAI.vertexAI(location: 'global')` for Gemini 3.0 Flash compatibility.

```dart
final model = FirebaseAI.vertexAI(location: 'global').generativeModel(
  model: 'gemini-2.0-flash',  // or 'gemini-2.5-flash', 'gemini-3-flash-preview'
  generationConfig: GenerationConfig(
    responseMimeType: 'application/json',
    responseSchema: schema,
    temperature: 0.0,  // 분류용은 0.0, 생성용은 0.3
  ),
);
```

---

## Common Tasks

### 새 서비스 추가

1. `lib/services/`에 서비스 클래스 생성
2. JSON Schema 정의 + 프롬프트 작성
3. `chat_provider.dart`에 provider 추가
4. `ChatController`에서 적절한 시점에 호출

### 상태 필드 추가

1. `learning_state.dart`에 필드 추가 + `copyWith()` 수정
2. `learning_state_provider.dart`에 업데이트 메서드 추가
3. `toJson()`/`fromJson()` 업데이트

### 프롬프트 수정

각 서비스의 `_buildPrompt()` 또는 `buildXxxPrompt()` 메서드에서 수정합니다. 프롬프트에는 필요한 상태 정보만 주입합니다.