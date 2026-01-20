import 'package:firebase_ai/firebase_ai.dart';
import '../models/message.dart';

/// Firebase AI(Vertex AI) Gemini 모델을 감싼 서비스다.
///
/// 토큰이 도착하는 즉시 UI가 갱신되도록 스트리밍 API를 제공한다.
class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    // Using Vertex AI backend via Firebase AI
    _model = FirebaseAI.vertexAI().generativeModel(
      model: 'gemini-2.0-flash',
    );
  }

  /// 프롬프트와 대화 히스토리를 받아 스트리밍 응답을 반환한다.
  ///
  /// 로컬 Message 객체를 Firebase AI `Content`로 변환해 전달한다.
  Stream<String> streamResponse(List<Message> history, String prompt) async* {
    final chat = _model.startChat(
      history: history.map((m) {
        return Content(m.role == MessageRole.user ? 'user' : 'model', [
          TextPart(m.content),
        ]);
      }).toList(),
    );

    final content = Content.text(prompt);
    final response = chat.sendMessageStream(content);

    await for (final chunk in response) {
      if (chunk.text != null) {
        yield chunk.text!;
      }
    }
  }
}
