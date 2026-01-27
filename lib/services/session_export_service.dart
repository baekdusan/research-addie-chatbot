import 'dart:convert';
import 'dart:html' as html;
import 'dart:math';
import 'package:intl/intl.dart';
import '../models/chat_session.dart';
import '../models/learning_state.dart';
import '../models/message.dart';
import '../models/state_change_event.dart';

/// 채팅 세션을 JSON 파일로 내보내는 서비스
///
/// 세션의 메시지와 상태 변화 이벤트를 시간순으로 정렬한 타임라인을 생성하고,
/// 브라우저를 통해 다운로드할 수 있도록 한다.
class SessionExportService {
  /// 세션을 JSON 파일로 내보내고 브라우저 다운로드를 트리거한다.
  Future<void> exportSession(
    ChatSession session,
    LearningState finalState,
  ) async {
    try {
      final exportData = _buildExportData(session, finalState);
      final filename = _generateFilename(session);
      _downloadJson(filename, exportData);
    } catch (e) {
      throw Exception('세션 내보내기 실패: $e');
    }
  }

  /// 내보낼 JSON 데이터를 구성한다.
  Map<String, dynamic> _buildExportData(
    ChatSession session,
    LearningState finalState,
  ) {
    return {
      'exportVersion': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'session': {
        'id': session.id,
        'title': session.title,
        'createdAt': session.createdAt.toIso8601String(),
      },
      'timeline': _buildTimeline(session.messages, session.stateChanges),
      'finalState': {
        'learnerProfile': finalState.learnerProfile.toJson(),
        'instructionalDesign': finalState.instructionalDesign.toJson(),
        'isDesigning': finalState.isDesigning,
        'isCourseCompleted': finalState.isCourseCompleted,
        'updatedAt': finalState.updatedAt.toIso8601String(),
      },
    };
  }

  /// 메시지와 상태 변화 이벤트를 시간순으로 정렬한 타임라인을 생성한다.
  List<Map<String, dynamic>> _buildTimeline(
    List<Message> messages,
    List<StateChangeEvent> stateChanges,
  ) {
    final timeline = <Map<String, dynamic>>[];

    // 메시지를 타임라인 엔트리로 변환
    for (final message in messages) {
      timeline.add({
        'type': 'message',
        'timestamp': message.timestamp.toIso8601String(),
        'role': message.role.name,
        'content': message.content,
      });
    }

    // 상태 변화를 타임라인 엔트리로 변환
    for (final event in stateChanges) {
      timeline.add({
        'type': 'stateChange',
        'timestamp': event.timestamp.toIso8601String(),
        'changeType': event.type.name,
        'changes': event.changes,
      });
    }

    // 타임스탬프 기준으로 정렬
    timeline.sort((a, b) {
      final timestampA = DateTime.parse(a['timestamp'] as String);
      final timestampB = DateTime.parse(b['timestamp'] as String);
      return timestampA.compareTo(timestampB);
    });

    return timeline;
  }

  /// 다운로드 파일명을 생성한다.
  ///
  /// 형식: YYYYMMDD_HHMM_<세션제목>.json
  /// 예: 20260127_1430_안녕.json
  String _generateFilename(ChatSession session) {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd_HHmm').format(now);

    // 제목에서 특수문자 제거 및 공백을 언더스코어로 변환
    var sanitizedTitle = session.title
        .replaceAll(RegExp(r'[^\w가-힣\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_');

    // 길이 제한 (정제된 문자열의 길이 사용)
    if (sanitizedTitle.length > 20) {
      sanitizedTitle = sanitizedTitle.substring(0, 20);
    }

    // 빈 문자열인 경우 기본값 사용
    if (sanitizedTitle.isEmpty) {
      sanitizedTitle = 'session';
    }

    return '${dateStr}_$sanitizedTitle.json';
  }

  /// JSON 데이터를 브라우저를 통해 다운로드한다.
  void _downloadJson(String filename, Map<String, dynamic> data) {
    // JSON을 보기 좋게 포맷팅
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    // Blob 생성
    final bytes = utf8.encode(jsonString);
    final blob = html.Blob([bytes], 'application/json');

    // 다운로드 URL 생성
    final url = html.Url.createObjectUrlFromBlob(blob);

    // 임시 앵커 엘리먼트를 생성하여 다운로드 트리거
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();

    // URL 정리
    html.Url.revokeObjectUrl(url);
  }
}
