import 'package:uuid/uuid.dart';

/// 채팅 메시지의 역할을 나타낸다.
enum MessageRole {
  user,
  model,
  system;

  String toJson() => name;
  static MessageRole fromJson(String json) => MessageRole.values.byName(json);
}

/// UI와 AI 서비스에서 사용하는 불변 메시지 모델이다.
class Message {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  /// 스트리밍 중인 메시지인지 여부다.
  final bool isStreaming;

  Message({
    String? id,
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.isStreaming = false,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  /// 불변성을 유지하기 위해 수정된 복사본을 반환한다.
  Message copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    bool? isStreaming,
  }) {
    return Message(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  /// 저장 또는 전송을 위해 메시지를 직렬화한다.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.toJson(),
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// 저장된 JSON에서 메시지를 역직렬화한다.
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      role: MessageRole.fromJson(json['role']),
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
