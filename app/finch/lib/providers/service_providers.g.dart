// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cryptoService)
final cryptoServiceProvider = CryptoServiceProvider._();

final class CryptoServiceProvider
    extends $FunctionalProvider<CryptoService, CryptoService, CryptoService>
    with $Provider<CryptoService> {
  CryptoServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cryptoServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cryptoServiceHash();

  @$internal
  @override
  $ProviderElement<CryptoService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CryptoService create(Ref ref) {
    return cryptoService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CryptoService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CryptoService>(value),
    );
  }
}

String _$cryptoServiceHash() => r'0d58462786084107e55cab9a337007c6d99a3d48';

@ProviderFor(contentKeyService)
final contentKeyServiceProvider = ContentKeyServiceProvider._();

final class ContentKeyServiceProvider
    extends
        $FunctionalProvider<
          ContentKeyService,
          ContentKeyService,
          ContentKeyService
        >
    with $Provider<ContentKeyService> {
  ContentKeyServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contentKeyServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contentKeyServiceHash();

  @$internal
  @override
  $ProviderElement<ContentKeyService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ContentKeyService create(Ref ref) {
    return contentKeyService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContentKeyService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContentKeyService>(value),
    );
  }
}

String _$contentKeyServiceHash() => r'e5a059e84dbf336859ec1cc80a195848b61f9cd3';

@ProviderFor(storageService)
final storageServiceProvider = StorageServiceProvider._();

final class StorageServiceProvider
    extends $FunctionalProvider<StorageService, StorageService, StorageService>
    with $Provider<StorageService> {
  StorageServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storageServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storageServiceHash();

  @$internal
  @override
  $ProviderElement<StorageService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StorageService create(Ref ref) {
    return storageService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StorageService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StorageService>(value),
    );
  }
}

String _$storageServiceHash() => r'4180349da34ceeca8d362aecfdd8707bbb91d0a9';

@ProviderFor(torService)
final torServiceProvider = TorServiceProvider._();

final class TorServiceProvider
    extends $FunctionalProvider<TorService, TorService, TorService>
    with $Provider<TorService> {
  TorServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'torServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$torServiceHash();

  @$internal
  @override
  $ProviderElement<TorService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TorService create(Ref ref) {
    return torService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TorService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TorService>(value),
    );
  }
}

String _$torServiceHash() => r'6a60f20b0aef7d7e85eb959e970dc1e9f7eb6435';

/// Reactive holder for the local `.onion` address. Updated by `main.dart`
/// after `TorService.createOnionService` returns; watched by
/// `ownEndpoints` so the published connection card picks up the onion
/// endpoint as soon as it's available.

@ProviderFor(OnionAddress)
final onionAddressProvider = OnionAddressProvider._();

/// Reactive holder for the local `.onion` address. Updated by `main.dart`
/// after `TorService.createOnionService` returns; watched by
/// `ownEndpoints` so the published connection card picks up the onion
/// endpoint as soon as it's available.
final class OnionAddressProvider
    extends $NotifierProvider<OnionAddress, String?> {
  /// Reactive holder for the local `.onion` address. Updated by `main.dart`
  /// after `TorService.createOnionService` returns; watched by
  /// `ownEndpoints` so the published connection card picks up the onion
  /// endpoint as soon as it's available.
  OnionAddressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onionAddressProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onionAddressHash();

  @$internal
  @override
  OnionAddress create() => OnionAddress();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$onionAddressHash() => r'f1d213aee3b6e1dcde4a6b9f7b5b805d9ab4a40a';

/// Reactive holder for the local `.onion` address. Updated by `main.dart`
/// after `TorService.createOnionService` returns; watched by
/// `ownEndpoints` so the published connection card picks up the onion
/// endpoint as soon as it's available.

abstract class _$OnionAddress extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(networkService)
final networkServiceProvider = NetworkServiceProvider._();

final class NetworkServiceProvider
    extends $FunctionalProvider<NetworkService, NetworkService, NetworkService>
    with $Provider<NetworkService> {
  NetworkServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkServiceHash();

  @$internal
  @override
  $ProviderElement<NetworkService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NetworkService create(Ref ref) {
    return networkService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NetworkService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NetworkService>(value),
    );
  }
}

String _$networkServiceHash() => r'f6bf0f4d4e0db8fda9cf980e02b35c63da50c02b';

/// Default binding is the in-memory mock so tests don't trigger native
/// channel activity. Production code overrides this in `main.dart` with
/// the real `MethodChannelMdnsService`.

@ProviderFor(mdnsService)
final mdnsServiceProvider = MdnsServiceProvider._();

/// Default binding is the in-memory mock so tests don't trigger native
/// channel activity. Production code overrides this in `main.dart` with
/// the real `MethodChannelMdnsService`.

final class MdnsServiceProvider
    extends $FunctionalProvider<MdnsService, MdnsService, MdnsService>
    with $Provider<MdnsService> {
  /// Default binding is the in-memory mock so tests don't trigger native
  /// channel activity. Production code overrides this in `main.dart` with
  /// the real `MethodChannelMdnsService`.
  MdnsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mdnsServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mdnsServiceHash();

  @$internal
  @override
  $ProviderElement<MdnsService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MdnsService create(Ref ref) {
    return mdnsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MdnsService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MdnsService>(value),
    );
  }
}

String _$mdnsServiceHash() => r'4c871553ae885ba8c6083dd18390f67ff1075fe2';

@ProviderFor(signalingService)
final signalingServiceProvider = SignalingServiceProvider._();

final class SignalingServiceProvider
    extends
        $FunctionalProvider<
          SignalingService,
          SignalingService,
          SignalingService
        >
    with $Provider<SignalingService> {
  SignalingServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signalingServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signalingServiceHash();

  @$internal
  @override
  $ProviderElement<SignalingService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SignalingService create(Ref ref) {
    return signalingService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignalingService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignalingService>(value),
    );
  }
}

String _$signalingServiceHash() => r'a078f428cc39d2f9f30be0f3ace88968744e83ce';

@ProviderFor(clock)
final clockProvider = ClockProvider._();

final class ClockProvider extends $FunctionalProvider<Clock, Clock, Clock>
    with $Provider<Clock> {
  ClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clockProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clockHash();

  @$internal
  @override
  $ProviderElement<Clock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Clock create(Ref ref) {
    return clock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Clock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Clock>(value),
    );
  }
}

String _$clockHash() => r'51dfbf45b6f587fbcfbb074c52c85416118b4ff3';

/// Shared in-memory feed-key cache. Hydrated at launch (main.dart) with
/// the identity's current key + the keys we've received from each follow,
/// then mutated by KeyRotationService and the sync engine. Tests get a
/// fresh empty cache.

@ProviderFor(feedKeyCache)
final feedKeyCacheProvider = FeedKeyCacheProvider._();

/// Shared in-memory feed-key cache. Hydrated at launch (main.dart) with
/// the identity's current key + the keys we've received from each follow,
/// then mutated by KeyRotationService and the sync engine. Tests get a
/// fresh empty cache.

final class FeedKeyCacheProvider
    extends $FunctionalProvider<FeedKeyCache, FeedKeyCache, FeedKeyCache>
    with $Provider<FeedKeyCache> {
  /// Shared in-memory feed-key cache. Hydrated at launch (main.dart) with
  /// the identity's current key + the keys we've received from each follow,
  /// then mutated by KeyRotationService and the sync engine. Tests get a
  /// fresh empty cache.
  FeedKeyCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedKeyCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedKeyCacheHash();

  @$internal
  @override
  $ProviderElement<FeedKeyCache> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FeedKeyCache create(Ref ref) {
    return feedKeyCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeedKeyCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeedKeyCache>(value),
    );
  }
}

String _$feedKeyCacheHash() => r'2e97e74cbc64b8a06b7dc0d767bb649815525c32';

/// Shared mutex serializing post publication against feed-key rotation
/// (Plan 13). All post-publish services and the rotation service must
/// pull from this single instance — without it, a post in flight could
/// be encrypted with a stale key mid-rotation.

@ProviderFor(publishLock)
final publishLockProvider = PublishLockProvider._();

/// Shared mutex serializing post publication against feed-key rotation
/// (Plan 13). All post-publish services and the rotation service must
/// pull from this single instance — without it, a post in flight could
/// be encrypted with a stale key mid-rotation.

final class PublishLockProvider
    extends $FunctionalProvider<PublishLock, PublishLock, PublishLock>
    with $Provider<PublishLock> {
  /// Shared mutex serializing post publication against feed-key rotation
  /// (Plan 13). All post-publish services and the rotation service must
  /// pull from this single instance — without it, a post in flight could
  /// be encrypted with a stale key mid-rotation.
  PublishLockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'publishLockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$publishLockHash();

  @$internal
  @override
  $ProviderElement<PublishLock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PublishLock create(Ref ref) {
    return publishLock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PublishLock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PublishLock>(value),
    );
  }
}

String _$publishLockHash() => r'2e4b82c49bcb0fa8a4072951aa7ccb3c3b0cb9e2';

@ProviderFor(saveService)
final saveServiceProvider = SaveServiceProvider._();

final class SaveServiceProvider
    extends $FunctionalProvider<SaveService, SaveService, SaveService>
    with $Provider<SaveService> {
  SaveServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'saveServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$saveServiceHash();

  @$internal
  @override
  $ProviderElement<SaveService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SaveService create(Ref ref) {
    return saveService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SaveService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SaveService>(value),
    );
  }
}

String _$saveServiceHash() => r'9d95bea13731c72442485145daa07bab5f97fe31';

@ProviderFor(commentService)
final commentServiceProvider = CommentServiceProvider._();

final class CommentServiceProvider
    extends $FunctionalProvider<CommentService, CommentService, CommentService>
    with $Provider<CommentService> {
  CommentServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'commentServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$commentServiceHash();

  @$internal
  @override
  $ProviderElement<CommentService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CommentService create(Ref ref) {
    return commentService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CommentService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CommentService>(value),
    );
  }
}

String _$commentServiceHash() => r'd3cc2c7daf83634d841cda24bbe124f77a122d89';

@ProviderFor(reactionService)
final reactionServiceProvider = ReactionServiceProvider._();

final class ReactionServiceProvider
    extends
        $FunctionalProvider<ReactionService, ReactionService, ReactionService>
    with $Provider<ReactionService> {
  ReactionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reactionServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reactionServiceHash();

  @$internal
  @override
  $ProviderElement<ReactionService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReactionService create(Ref ref) {
    return reactionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReactionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReactionService>(value),
    );
  }
}

String _$reactionServiceHash() => r'd1f0c6141b6ec35b0a8bc17e16f45a292712375a';
