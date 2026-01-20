// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$geminiServiceHash() => r'936686efdf1e9bbe5ce133c174ae5b0704cf45a5';

/// See also [geminiService].
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
String _$activeSessionHash() => r'f3868899d1d9322fc2e4814f5d4d810b3e2c540d';

/// See also [activeSession].
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

/// See also [ChatSessions].
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

/// See also [ActiveSessionId].
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
String _$chatControllerHash() => r'b2c694176883514dc166889fb502304d2894da0d';

/// See also [ChatController].
@ProviderFor(ChatController)
final chatControllerProvider =
    AutoDisposeAsyncNotifierProvider<ChatController, void>.internal(
  ChatController.new,
  name: r'chatControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chatControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ChatController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
