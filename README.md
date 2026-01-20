# Research ADDIE Chatbot

ADDIE 모델 기반 적응형 학습 튜터 시스템

## 프로젝트 개요

학습자의 니즈를 분석하고, 교수설계안을 생성하며, 대화형으로 수업을 진행하는 AI 튜터 챗봇

### 핵심 기능 (계획)

```
[1단계: 니즈 분석] → [2단계: 교수설계안 생성] → [3단계: 대화형 수업]
     ↓                      ↓                         ↓
  구조화된 질문          ADDIE 기반 설계           적응형 튜터링
  학습자 프로파일        학습목표/콘텐츠 구조화      진도 추적 & 피드백
```

## 기술 스택

| 구분 | 기술 |
|------|------|
| 프론트엔드 | Flutter Web |
| 상태 관리 | Riverpod (코드 생성) |
| AI 백엔드 | Firebase AI (Vertex AI) - Gemini 2.0 Flash |
| 데이터베이스 | Firestore (예정) |

## 프로젝트 구조

```
lib/
├── main.dart                 # 앱 진입점
├── firebase_options.dart     # Firebase 설정
├── models/
│   ├── message.dart          # 메시지 모델
│   └── chat_session.dart     # 채팅 세션 모델
├── providers/
│   └── chat_provider.dart    # Riverpod 프로바이더
├── services/
│   └── gemini_service.dart   # Firebase AI 서비스
├── screens/
│   └── chat_screen.dart      # 메인 채팅 화면
└── widgets/
    ├── chat_view.dart        # 채팅 뷰
    ├── chat_input.dart       # 입력 위젯
    ├── message_bubble.dart   # 메시지 버블
    └── sidebar.dart          # 사이드바
```

## 실행 방법

```bash
# 의존성 설치
flutter pub get

# 코드 생성 (Riverpod)
flutter pub run build_runner build --delete-conflicting-outputs

# 웹으로 실행
flutter run -d chrome
```

## Firebase 설정

1. Firebase 프로젝트 생성
2. Vertex AI in Firebase API 활성화
3. Web App 등록
4. `flutterfire configure` 실행

```bash
# Firebase CLI 설치
npm install -g firebase-tools
firebase login

# FlutterFire CLI 설치
dart pub global activate flutterfire_cli
export PATH="$PATH":"$HOME/.pub-cache/bin"

# 설정 생성
flutterfire configure --project=your-project-id
```

## 보안 주의사항

- `lib/firebase_options.dart`에는 API 키와 프로젝트 식별자가 포함됩니다.
- 이 파일은 `.gitignore`에 포함되어 있어야 하며, 레포지토리에 커밋하지 않습니다.
- 로컬에서 설정하려면 `lib/firebase_options_example.dart`를 복사해
  `lib/firebase_options.dart`로 저장하고 값을 채우거나 `flutterfire configure`를 실행하세요.
- 이미 추적 중인 경우 다음을 실행해 Git 기록에서 제거하세요:

```bash
git rm --cached lib/firebase_options.dart
```

## 구현 계획

### Phase 1: 기본 채팅 (완료)
- [x] Flutter 프로젝트 세팅
- [x] Firebase AI 연동
- [x] 기본 채팅 UI
- [x] 스트리밍 응답

### Phase 2: 멀티 페이즈 시스템
- [ ] 학습 페이즈 상태 관리
- [ ] 페이즈별 System Instruction
- [ ] 니즈 분석 플로우

### Phase 3: 교수설계 생성
- [ ] ADDIE 기반 프롬프트
- [ ] JSON 구조화 출력
- [ ] 설계안 저장/수정

### Phase 4: 대화형 수업
- [ ] 교수설계안 기반 튜터링
- [ ] 진도 추적
- [ ] 적응형 피드백

### Phase 5: 데이터 저장
- [ ] Firestore 연동
- [ ] 학습자 프로파일 저장
- [ ] 세션 히스토리 저장

## 핵심 기술 접근법

### 프롬프트 체이닝

복잡한 작업을 단계별 프롬프트로 분리:

```dart
// 1단계: 니즈 분석
final goal = await ai.generate("학습 목표를 파악하세요");

// 2단계: 결과를 다음 단계 입력으로
final design = await ai.generate("목표: $goal\n교수설계안을 작성하세요");

// 3단계: 설계안 기반 수업
final lesson = await ai.generate("설계안: $design\n첫 수업을 진행하세요");
```

### 페이즈별 System Instruction

```dart
enum LearningPhase { needsAnalysis, designGeneration, lesson, assessment }

String getSystemInstruction(LearningPhase phase) {
  switch (phase) {
    case LearningPhase.needsAnalysis:
      return "당신은 학습 니즈 분석 전문가입니다...";
    case LearningPhase.designGeneration:
      return "당신은 ADDIE 모델 기반 교수설계 전문가입니다...";
    case LearningPhase.lesson:
      return "당신은 친근한 튜터입니다...";
  }
}
```

## 라이선스

MIT License
