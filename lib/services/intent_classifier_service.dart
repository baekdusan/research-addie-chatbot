import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';

enum IntentResult {
  inClass,
  outOfClass;

  static IntentResult fromJson(String value) {
    return value == 'out_of_class' ? IntentResult.outOfClass : IntentResult.inClass;
  }
}

class IntentClassifierService {
  Future<IntentResult> classify(String userText) async {
    final schema = Schema.object(
      properties: {
        'intent': Schema.enumString(
          enumValues: ['out_of_class', 'in_class'],
          description: '사용자 발화 의도 분류',
        ),
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

    final prompt = _buildPrompt(userText);
    final response = await model.generateContent([Content.text(prompt)]);
    final raw = response.text;
    if (raw == null || raw.isEmpty) {
      return IntentResult.inClass;
    }

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final intent = data['intent'] as String?;
      if (intent == null) return IntentResult.inClass;
      return IntentResult.fromJson(intent);
    } catch (_) {
      return IntentResult.inClass;
    }
  }

  String _buildPrompt(String userText) {
    return '''너는 학습자의 발화 의도를 분류하는 분류기다.
오직 분류만 수행하라. 정보 추출이나 답변 생성은 하지 마라.

[분류 규칙]
- out_of_class: 학습 주제, 목표, 본인의 수준, 선호 말투, 학습 순서 변경 등 '수업의 틀'을 바꾸는 발화
- in_class: 현재 진행 중인 수업 내용(개념 질문, 풀이 확인, 예시 요청, 정답 시도 등)에 대한 발화

[중요]
- 애매하면 in_class로 분류하라. (default=in_class)

[Few-shot 예시]
- "파이썬 기초를 배우고 싶어" -> out_of_class
- "난 완전 초보야" -> out_of_class
- "반말로 해줘" -> out_of_class
- "목표를 계산기 만들기로 바꾸고 싶어" -> out_of_class
- "이 순서 말고 다른 것부터 하고 싶어" -> out_of_class
- "변수가 뭐야?" -> in_class
- "정답은 3번인 것 같아" -> in_class
- "예시 하나만 더 들어줘" -> in_class

[입력]
$userText

[출력 규칙]
- 반드시 JSON만 출력하라.''';
  }
}
