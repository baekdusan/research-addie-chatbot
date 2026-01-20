import 'package:uuid/uuid.dart';
import 'message.dart';

/// 하나의 채팅 대화를 표현하는 불변(immutable) 데이터 모델.
///
/// 고유 ID, 제목, 메시지 목록([Message]), 생성 시간을 포함하며,
/// 사이드바의 세션 목록과 [ChatView]에서 대화 내용을 표시하는 데 사용된다.
class ChatSession {
  final String id;
  final String title;
  final List<Message> messages;
  final DateTime createdAt;

  ChatSession({
    String? id,
    required this.title,
    List<Message>? messages,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       messages = messages ?? [],
       createdAt = createdAt ?? DateTime.now();

  /// 불변성 패턴 구현을 위한 복사 메서드.
  ///
  /// 메시지 추가, 제목 변경 등 세션 업데이트 시 원본을 수정하지 않고
  /// 새 [ChatSession] 인스턴스를 생성한다.
  ChatSession copyWith({
    String? id,
    String? title,
    List<Message>? messages,
    DateTime? createdAt,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 세션을 JSON [Map]으로 변환하는 직렬화 메서드.
  ///
  /// 각 메시지도 재귀적으로 [Message.toJson]을 호출하여 직렬화하며,
  /// 로컬 저장소에 대화 기록을 저장할 때 사용한다.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// JSON [Map]에서 [ChatSession] 인스턴스를 복원하는 팩토리 생성자.
  ///
  /// 앱 재시작 시 저장된 대화 기록을 불러오는 데 사용한다.
  /// 내부 메시지 목록도 [Message.fromJson]을 통해 복원된다.
  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      title: json['title'],
      messages: (json['messages'] as List)
          .map((m) => Message.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
