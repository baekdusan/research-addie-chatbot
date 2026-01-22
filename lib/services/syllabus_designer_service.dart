import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import '../models/learner_profile.dart';
import '../models/instructional_design.dart';

class SyllabusDesignerService {
  Future<List<Step>> generate(
    LearnerProfile profile, {
    String? redesignRequest,
  }) async {
    final stepSchema = Schema.object(
      properties: {
        'step': Schema.integer(description: '단계 번호'),
        'topic': Schema.string(description: '단계 소주제'),
        'objective': Schema.string(description: '단계 학습 목표'),
      },
    );

    final schema = Schema.object(
      properties: {
        'syllabus': Schema.array(
          items: stepSchema,
          description: '1~5개 단계 배열',
        ),
      },
    );

    final model = FirebaseAI.vertexAI(location: 'global').generativeModel(
      model: 'gemini-3-flash-preview',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: schema,
        temperature: 0.3,
      ),
    );

    final prompt = _buildPrompt(profile, redesignRequest: redesignRequest);
    final response = await model.generateContent([Content.text(prompt)]);
    final raw = response.text;
    if (raw == null || raw.isEmpty) {
      throw StateError('Empty syllabus response');
    }

    final data = jsonDecode(raw) as Map<String, dynamic>;
    final list = data['syllabus'];
    if (list is! List || list.isEmpty) {
      throw StateError('Invalid syllabus response');
    }

    return list
        .map((item) => Step.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  String _buildPrompt(
    LearnerProfile profile, {
    String? redesignRequest,
  }) {
    final level = profile.level?.name ?? '미정';
    final tone = profile.tonePreference?.name ?? '미정';
    final redesignNote = redesignRequest == null
        ? ''
        : '\n[재설계 요청]\n- $redesignRequest\n- 위 요청을 반드시 반영하라.';
    return '''너는 전문 교수설계자(Instructional Designer)다.
학습자의 프로필을 바탕으로 '주제(subject)'를 마스터하여 '목표(goal)'에 도달할 수 있는 커리큘럼을 설계하라.

[입력 정보]
- subject: ${profile.subject}
- goal: ${profile.goal}
- level: $level
- tone_preference: $tone
$redesignNote

[설계 원칙]
1) 단계는 1~5개로 구성하라.
2) 주제가 매우 쉬우면 단계를 줄여도 된다.
3) 불필요하게 길게 늘어뜨리지 말고 목표 달성에 필요한 최소 단계만 제시하라.
4) 각 단계는 명확한 소주제(topic)와 구체적인 학습목표(objective)를 포함해야 한다.
5) level에 맞게 난이도를 조절하라.
6) 최종 단계는 goal과 직접 연결되어야 한다.
7) 각 단계는 이전 단계의 지식을 기반으로 해야 한다.

[출력 규칙]
- 반드시 JSON만 출력하라.''';
  }
}
