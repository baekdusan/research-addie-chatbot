import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import '../models/learning_state.dart';
import '../models/learner_profile.dart';

class AnalystResult {
  final String response;
  final String? subject;
  final String? goal;
  final LearnerLevel? level;
  final TonePreference? tonePreference;

  AnalystResult({
    required this.response,
    this.subject,
    this.goal,
    this.level,
    this.tonePreference,
  });
}

class FeedbackResult {
  final String response;
  final LearnerLevel? level;
  final TonePreference? tonePreference;
  final bool needsRedesign;
  final bool explicitChange;
  final String? redesignRequest;

  FeedbackResult({
    required this.response,
    required this.needsRedesign,
    required this.explicitChange,
    this.redesignRequest,
    this.level,
    this.tonePreference,
  });
}

class ConversationalAgentService {
  String buildTutorStreamingPrompt(
    LearningState state,
    String userText,
    List<String> history,
  ) {
    final profile = state.learnerProfile;
    final design = state.instructionalDesign;
    final level = profile.level?.name ?? '미정';
    final toneDisplay = profile.tonePreference?.name ?? '미정';
    final toneForResponse = profile.tonePreference?.name ?? 'kind';
    final historyBlock = history.isEmpty ? '없음' : history.join('\n');

    final syllabusBlock = design.syllabus.asMap().entries.map((e) {
      final idx = e.key + 1;
      final step = e.value;
      return '$idx. ${step.topic} - ${step.objective}';
    }).join('\n');

    return '''너는 학습자를 돕는 친절하고 전문적인 튜터다.
학습 로드맵을 참고하여 학습자의 흐름에 맞게 자연스럽게 수업을 진행하라.

[현재 학습 상태]
- 주제(subject): ${profile.subject}
- 목표(goal): ${profile.goal}
- 수준(level): $level
- 선호 말투(tone_preference): $toneDisplay

[학습 로드맵]
$syllabusBlock

[최근 대화 요약]
$historyBlock

[튜터링 원칙]
1) 정답을 먼저 말하지 마라. (비계 설정/Scaffolding)
2) 사용자가 어렵다고 하면 더 쉬운 설명과 더 작은 예시로 내려가라.
3) 이해 확인 질문은 필요할 때만 0~1개로 제한하라.
4) 로드맵을 참고하되, 대화 흐름에 따라 유연하게 진행하라.
5) 말투는 $toneForResponse에 맞춰라.
6) tone_preference가 미정이면 기본적으로 kind 말투로 응답하라.
7) 설명은 지나치게 짧지 않게 3~6문장 정도로 충분히 풀어라.
8) 사용자가 "그냥 알려줘"라고 하면 질문 없이 설명만 하라.
9) 로드맵의 모든 내용을 충분히 다뤘다고 판단되면, 학습 완료 여부를 자연스럽게 물어보라.

[입력]
$userText

[출력 규칙]
- 반드시 한국어 자연어로만 답하라.
- JSON을 출력하지 마라.
''';
  }

  Future<AnalystResult> runAnalyst(
    LearningState state,
    String userText,
  ) async {
    final schema = Schema.object(
      properties: {
        'extracted_info': Schema.object(
          properties: {
            'subject': Schema.string(description: '학습 주제'),
            'goal': Schema.string(description: '학습 목표'),
            'level': Schema.enumString(
              enumValues: ['beginner', 'intermediate', 'expert'],
              description: '학습자 수준',
            ),
            'tone_preference': Schema.enumString(
              enumValues: ['kind', 'formal', 'casual'],
              description: '선호 말투',
            ),
          },
          optionalProperties: [
            'subject',
            'goal',
            'level',
            'tone_preference',
          ],
        ),
        'explicit_fields': Schema.object(
          properties: {
            'subject': Schema.boolean(description: 'subject가 명시적으로 언급됨'),
            'goal': Schema.boolean(description: 'goal이 명시적으로 언급됨'),
            'level': Schema.boolean(description: 'level이 명시적으로 언급됨'),
            'tone_preference':
                Schema.boolean(description: 'tone_preference가 명시적으로 언급됨'),
          },
          optionalProperties: [
            'subject',
            'goal',
            'level',
            'tone_preference',
          ],
        ),
        'response': Schema.string(description: '사용자에게 보여줄 응답'),
      },
    );

    final model = FirebaseAI.vertexAI().generativeModel(
      model: 'gemini-2.0-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: schema,
        temperature: 0.0,
      ),
    );

    final prompt = _buildAnalystPrompt(state, userText);
    final response = await model.generateContent([Content.text(prompt)]);
    final raw = response.text;
    if (raw == null || raw.isEmpty) {
      return AnalystResult(response: '조금 더 자세히 말씀해 주실 수 있을까요?');
    }

    final data = jsonDecode(raw) as Map<String, dynamic>;
    final extracted =
        (data['extracted_info'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};

    final explicit =
        (data['explicit_fields'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};

    final subjectExplicit = explicit['subject'] as bool? ?? false;
    final goalExplicit = explicit['goal'] as bool? ?? false;
    final levelExplicit = explicit['level'] as bool? ?? false;
    final toneExplicit = explicit['tone_preference'] as bool? ?? false;

    final subject = subjectExplicit
        ? _normalizeText(extracted['subject'] as String?)
        : null;
    final goal =
        goalExplicit ? _normalizeText(extracted['goal'] as String?) : null;

    return AnalystResult(
      response: data['response'] as String? ?? '조금 더 자세히 말씀해 주실 수 있을까요? ',
      subject: subject,
      goal: goal,
      level: levelExplicit && extracted['level'] != null
          ? LearnerLevel.values.byName(extracted['level'] as String)
          : null,
      tonePreference: toneExplicit && extracted['tone_preference'] != null
          ? TonePreference.values.byName(
              extracted['tone_preference'] as String,
            )
          : null,
    );
  }

  Future<FeedbackResult> runFeedback(
    LearningState state,
    String userText,
  ) async {
    final schema = Schema.object(
      properties: {
        'profile_update': Schema.object(
          properties: {
            'level': Schema.enumString(
              enumValues: ['beginner', 'intermediate', 'expert'],
              description: '수준 변경 요청',
            ),
            'tone_preference': Schema.enumString(
              enumValues: ['kind', 'formal', 'casual'],
              description: '말투 변경 요청',
            ),
          },
          optionalProperties: ['level', 'tone_preference'],
        ),
        'response': Schema.string(description: '피드백 수용 응답'),
        'needs_redesign': Schema.boolean(description: '재설계 필요 여부'),
        'explicit_change':
            Schema.boolean(description: '변경 요청이 명시적으로 존재'),
        'redesign_request':
            Schema.string(description: '재설계에 반영할 구체적 요청'),
      },
      optionalProperties: ['redesign_request'],
    );

    final model = FirebaseAI.vertexAI().generativeModel(
      model: 'gemini-2.0-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: schema,
        temperature: 0.3,
      ),
    );

    final prompt = _buildFeedbackPrompt(state, userText);
    final response = await model.generateContent([Content.text(prompt)]);
    final raw = response.text;
    if (raw == null || raw.isEmpty) {
      return FeedbackResult(
        response: '알겠어요. 필요한 부분을 조정해볼게요.',
        needsRedesign: false,
        explicitChange: false,
      );
    }

    final data = jsonDecode(raw) as Map<String, dynamic>;
    final update =
        (data['profile_update'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    return FeedbackResult(
      response: data['response'] as String? ??
          '알겠어요. 필요한 부분을 조정해볼게요.',
      needsRedesign: data['needs_redesign'] as bool? ?? false,
      explicitChange: data['explicit_change'] as bool? ?? false,
      redesignRequest: _normalizeText(data['redesign_request'] as String?),
      level: update['level'] != null
          ? LearnerLevel.values.byName(update['level'] as String)
          : null,
      tonePreference: update['tone_preference'] != null
          ? TonePreference.values.byName(update['tone_preference'] as String)
          : null,
    );
  }

  String _buildAnalystPrompt(LearningState state, String userText) {
    final profile = state.learnerProfile;
    final level = profile.level?.name ?? '미정';
    final tone = profile.tonePreference?.name ?? '미정';
    return '''너는 학습자의 정보를 수집하는 친절한 인터뷰어다.
자연스러운 대화를 통해 학습자의 학습 주제(subject), 목표(goal), 수준(level), 선호 말투(tone_preference)를 파악하라.

[수집할 정보]
- subject: 무엇을 배우고 싶은가?
- goal: 이 학습으로 무엇을 하고 싶은가?
- level: beginner/intermediate/expert 중 하나
- tone_preference: kind/formal/casual 중 하나

[대화 원칙]
1) 한 번에 하나의 정보만 물어보라.
2) 이미 파악된 정보는 다시 묻지 마라.
3) 사용자가 이미 답한 정보는 extracted_info에 반드시 반영하라.
4) 필수 정보(subject, goal)가 모두 파악되면:
   - 사용자에게 "로드맵(학습 계획)을 만들겠다"고 안내하라.
   - 추가 질문은 하지 마라.
5) 현재 정보가 '미정'이면 그 정보를 얻기 위한 질문을 우선하라.
6) 사용자가 명시적으로 언급하지 않은 값은 절대 추측하지 말고 null로 두어라.
7) explicit_fields에 true로 표시된 항목만 extracted_info에 값을 채우고, 나머지는 null로 두어라.

[현재까지 파악된 정보]
- subject: ${profile.subject}
- goal: ${profile.goal}
- level: $level
- tone_preference: $tone

[입력]
$userText

[출력 규칙]
- 반드시 JSON만 출력하라.
- extracted_info의 각 필드는 새로 파악되었으면 값을 넣고, 파악되지 않았으면 null로 두어라.
- explicit_fields는 각 항목이 명시적으로 언급되었는지 true/false로 표시하라.
- response는 사용자에게 보여줄 자연스러운 한국어 한 문단이다.''';
  }

  String _buildFeedbackPrompt(LearningState state, String userText) {
    final profile = state.learnerProfile;
    final design = state.instructionalDesign;
    final level = profile.level?.name ?? '미정';
    final tone = profile.tonePreference?.name ?? '미정';

    final syllabusBlock = design.syllabus.asMap().entries.map((e) {
      final idx = e.key + 1;
      final step = e.value;
      return '$idx. ${step.topic}';
    }).join('\n');

    return '''너는 학습자의 피드백을 수용하는 유연한 튜터다.
학습자의 요청을 반영하여 프로필을 업데이트하고, 필요하면 학습 로드맵 재설계를 요청하라.

[현재 학습 상태]
- 주제(subject): ${profile.subject}
- 목표(goal): ${profile.goal}
- 수준(level): $level
- 선호 말투(tone_preference): $tone

[학습 로드맵]
$syllabusBlock

[피드백 처리 원칙]
1) 피드백을 긍정적으로 수용하라.
2) 난이도/말투 변경 요청은 profile_update에 반영하라.
3) 학습 경로 자체의 변경(목표 변경, 주제 변경, 순서 변경)이 필요하면 needs_redesign=true로 설정하라.
4) 단순 난이도/스타일 조정은 needs_redesign 없이 처리하라.
5) response는 피드백 수용 + 수업 계속 안내를 포함하라.
6) 사용자가 명시적으로 목표/주제/순서 변경을 요청한 경우에만 explicit_change=true로 설정하라.
7) unrelated한 잡담/감정 표현이면 explicit_change=false로 두고 needs_redesign도 false로 두어라.
8) explicit_change=true인 경우, 사용자의 요청을 요약해 redesign_request에 한국어 한 문장으로 담아라. 그렇지 않으면 null로 두어라.

[입력]
$userText

[출력 규칙]
- 반드시 JSON만 출력하라.
- profile_update의 각 필드는 변경이 필요하면 값을 넣고, 없으면 null로 두어라.''';
  }

  String? _normalizeText(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.toLowerCase() == 'null') return null;
    return trimmed;
  }

}
