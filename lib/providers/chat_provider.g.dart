// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$geminiServiceHash() => r'936686efdf1e9bbe5ce133c174ae5b0704cf45a5';

/// [GeminiService]의 싱글톤 인스턴스를 제공하는 프로바이더.
///
/// `keepAlive: true` 설정으로 앱 생명주기 동안 인스턴스가 유지되어
/// 불필요한 재생성을 방지하고 연결 상태를 보존한다.
///
/// Copied from [geminiService].
@ProviderFor(geminiService)
final geminiServiceProvider = Provider<GeminiService>.internal(
  geminiService,
  name: r'geminiServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$geminiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef GeminiServiceRef = ProviderRef<GeminiService>;
String _$intentClassifierServiceHash() =>
    r'8caa31543ce798edde2e7886a54a9376cf54bd49';

/// See also [intentClassifierService].
@ProviderFor(intentClassifierService)
final intentClassifierServiceProvider =
    Provider<IntentClassifierService>.internal(
  intentClassifierService,
  name: r'intentClassifierServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$intentClassifierServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef IntentClassifierServiceRef = ProviderRef<IntentClassifierService>;
String _$conversationalAgentServiceHash() =>
    r'5d16e2ab8e3fa9be0004dd96a556e55cf27abeff';

/// See also [conversationalAgentService].
@ProviderFor(conversationalAgentService)
final conversationalAgentServiceProvider =
    Provider<ConversationalAgentService>.internal(
  conversationalAgentService,
  name: r'conversationalAgentServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$conversationalAgentServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ConversationalAgentServiceRef = ProviderRef<ConversationalAgentService>;
String _$syllabusDesignerServiceHash() =>
    r'c891dcffc465873fc74df25afe68c6f4a1686a61';

/// See also [syllabusDesignerService].
@ProviderFor(syllabusDesignerService)
final syllabusDesignerServiceProvider =
    Provider<SyllabusDesignerService>.internal(
  syllabusDesignerService,
  name: r'syllabusDesignerServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$syllabusDesignerServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SyllabusDesignerServiceRef = ProviderRef<SyllabusDesignerService>;
String _$sessionExportServiceHash() =>
    r'c151b5cff50c19697e29b5b5550656f044271359';

/// See also [sessionExportService].
@ProviderFor(sessionExportService)
final sessionExportServiceProvider = Provider<SessionExportService>.internal(
  sessionExportService,
  name: r'sessionExportServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sessionExportServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SessionExportServiceRef = ProviderRef<SessionExportService>;
String _$activeSessionHash() => r'f3868899d1d9322fc2e4814f5d4d810b3e2c540d';

/// [activeSessionIdProvider]와 [chatSessionsProvider]를 조합하여 현재 활성화된 [ChatSession] 객체를 반환하는 파생(computed) 프로바이더.
///
/// UI에서 현재 대화 내용을 표시할 때 `ref.watch`로 구독하며,
/// 활성 ID가 없거나 해당 세션이 없으면 null을 반환한다.
///
/// Copied from [activeSession].
@ProviderFor(activeSession)
final activeSessionProvider = AutoDisposeProvider<ChatSession?>.internal(
  activeSession,
  name: r'activeSessionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeSessionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ActiveSessionRef = AutoDisposeProviderRef<ChatSession?>;
String _$chatSessionsHash() => r'34336da7cbc636e90ad5d058d40214bef848cd2f';

/// 앱의 모든 채팅 세션을 관리하는 상태 노티파이어.
///
/// 세션 목록을 [List<ChatSession>]으로 보관하며 추가, 수정, 삭제 기능을 제공한다.
/// [Sidebar]의 세션 히스토리 표시와 세션 전환에 사용된다.
///
/// Copied from [ChatSessions].
@ProviderFor(ChatSessions)
final chatSessionsProvider =
    AutoDisposeNotifierProvider<ChatSessions, List<ChatSession>>.internal(
  ChatSessions.new,
  name: r'chatSessionsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$chatSessionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ChatSessions = AutoDisposeNotifier<List<ChatSession>>;
String _$activeSessionIdHash() => r'd0722f2f45afec2aebe6ea2b0ab34a426cc8d178';

/// 현재 화면에 표시 중인 채팅 세션의 ID를 추적하는 상태 노티파이어.
///
/// null이면 아직 세션이 선택되지 않은 상태이며,
/// 첫 메시지 전송 시 새 세션이 자동 생성된다.
///
/// Copied from [ActiveSessionId].
@ProviderFor(ActiveSessionId)
final activeSessionIdProvider =
    AutoDisposeNotifierProvider<ActiveSessionId, String?>.internal(
  ActiveSessionId.new,
  name: r'activeSessionIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeSessionIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ActiveSessionId = AutoDisposeNotifier<String?>;
String _$chatControllerHash() => r'd48164ca12342d9c8a2434223224ef919b16e67a';

/// 채팅의 핵심 비즈니스 로직을 담당하는 컨트롤러.
///
/// 사용자 메시지 전송, AI 응답 스트리밍 수신, 세션 상태 업데이트를 조율한다.
/// [ChatInput]에서 메시지 전송 시, [Sidebar]에서 새 채팅 생성 시 호출된다.
///
/// Copied from [ChatController].
@ProviderFor(ChatController)
final chatControllerProvider =
    AsyncNotifierProvider<ChatController, void>.internal(
  ChatController.new,
  name: r'chatControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chatControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ChatController = AsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
