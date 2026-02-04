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
/// Version 2.0: 간소화된 타임라인 형식
/// - 학생 메시지 (student)
/// - 튜터 메시지 (tutor)
/// - 프로필 업데이트 (profile): subject, goal, level, tonePreference 변경
/// - 학습 플랜 (syllabus): 커리큘럼 + 교수설계 이론
///
/// Tutor agent가 참조하는 학습 상태 데이터를 시간순으로 정렬하여 브라우저를 통해 다운로드한다.
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
      'exportVersion': '2.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'session': {
        'id': session.id,
        'title': session.title,
        'createdAt': session.createdAt.toIso8601String(),
      },
      'timeline': _buildSimplifiedTimeline(session.messages, session.stateChanges),
    };
  }

  /// 간소화된 타임라인 생성 (학생, 튜터, 학습 상태만 포함)
  ///
  /// 포함되는 항목:
  /// - student: 학생 메시지 (MessageRole.user)
  /// - tutor: 튜터 메시지 (MessageRole.model)
  /// - profile: 프로필 업데이트 (StateChangeType.profileUpdated)
  /// - syllabus: 학습 플랜 업데이트 + 교수설계 이론 (StateChangeType.syllabusGenerated)
  List<Map<String, dynamic>> _buildSimplifiedTimeline(
    List<Message> messages,
    List<StateChangeEvent> stateChanges,
  ) {
    final timeline = <Map<String, dynamic>>[];

    // 학생/튜터 메시지만 추가
    for (final message in messages) {
      if (message.role == MessageRole.user) {
        timeline.add({
          'type': 'student',
          'timestamp': message.timestamp.toIso8601String(),
          'content': message.content,
        });
      } else if (message.role == MessageRole.model) {
        timeline.add({
          'type': 'tutor',
          'timestamp': message.timestamp.toIso8601String(),
          'content': message.content,
        });
      }
      // MessageRole.system 제외
    }

    // 학습 상태 업데이트 추가
    for (final event in stateChanges) {
      if (event.type == StateChangeType.profileUpdated) {
        // Profile 변경 (subject, goal, level, tonePreference)
        timeline.add({
          'type': 'profile',
          'timestamp': event.timestamp.toIso8601String(),
          'profile': event.changes,
        });
      } else if (event.type == StateChangeType.syllabusGenerated) {
        // Syllabus 생성 + ResourceCache (theories)
        final steps = event.changes['steps'] as List?;
        if (steps != null && steps.isNotEmpty) {
          timeline.add({
            'type': 'syllabus',
            'timestamp': event.timestamp.toIso8601String(),
            'syllabus': steps,
            'theories': event.changes['theories'],
          });
        }
      }
      // 다른 StateChangeType 제외
    }

    // 시간순 정렬
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
