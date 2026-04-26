// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reactions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$reactionsHash() => r'85badbd87deeabebbca1ce7a06cf074a8422d967';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [reactions].
@ProviderFor(reactions)
const reactionsProvider = ReactionsFamily();

/// See also [reactions].
class ReactionsFamily extends Family<AsyncValue<ReactionSummary>> {
  /// See also [reactions].
  const ReactionsFamily();

  /// See also [reactions].
  ReactionsProvider call(String postId) {
    return ReactionsProvider(postId);
  }

  @override
  ReactionsProvider getProviderOverride(covariant ReactionsProvider provider) {
    return call(provider.postId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'reactionsProvider';
}

/// See also [reactions].
class ReactionsProvider extends AutoDisposeFutureProvider<ReactionSummary> {
  /// See also [reactions].
  ReactionsProvider(String postId)
    : this._internal(
        (ref) => reactions(ref as ReactionsRef, postId),
        from: reactionsProvider,
        name: r'reactionsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$reactionsHash,
        dependencies: ReactionsFamily._dependencies,
        allTransitiveDependencies: ReactionsFamily._allTransitiveDependencies,
        postId: postId,
      );

  ReactionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
  }) : super.internal();

  final String postId;

  @override
  Override overrideWith(
    FutureOr<ReactionSummary> Function(ReactionsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ReactionsProvider._internal(
        (ref) => create(ref as ReactionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ReactionSummary> createElement() {
    return _ReactionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ReactionsProvider && other.postId == postId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ReactionsRef on AutoDisposeFutureProviderRef<ReactionSummary> {
  /// The parameter `postId` of this provider.
  String get postId;
}

class _ReactionsProviderElement
    extends AutoDisposeFutureProviderElement<ReactionSummary>
    with ReactionsRef {
  _ReactionsProviderElement(super.provider);

  @override
  String get postId => (origin as ReactionsProvider).postId;
}

String _$reactionControllerHash() =>
    r'e62f573743ae5870ca12a68033def4b67a5627dd';

abstract class _$ReactionController extends BuildlessAutoDisposeNotifier<void> {
  late final String postId;

  void build(String postId);
}

/// See also [ReactionController].
@ProviderFor(ReactionController)
const reactionControllerProvider = ReactionControllerFamily();

/// See also [ReactionController].
class ReactionControllerFamily extends Family<void> {
  /// See also [ReactionController].
  const ReactionControllerFamily();

  /// See also [ReactionController].
  ReactionControllerProvider call(String postId) {
    return ReactionControllerProvider(postId);
  }

  @override
  ReactionControllerProvider getProviderOverride(
    covariant ReactionControllerProvider provider,
  ) {
    return call(provider.postId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'reactionControllerProvider';
}

/// See also [ReactionController].
class ReactionControllerProvider
    extends AutoDisposeNotifierProviderImpl<ReactionController, void> {
  /// See also [ReactionController].
  ReactionControllerProvider(String postId)
    : this._internal(
        () => ReactionController()..postId = postId,
        from: reactionControllerProvider,
        name: r'reactionControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$reactionControllerHash,
        dependencies: ReactionControllerFamily._dependencies,
        allTransitiveDependencies:
            ReactionControllerFamily._allTransitiveDependencies,
        postId: postId,
      );

  ReactionControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
  }) : super.internal();

  final String postId;

  @override
  void runNotifierBuild(covariant ReactionController notifier) {
    return notifier.build(postId);
  }

  @override
  Override overrideWith(ReactionController Function() create) {
    return ProviderOverride(
      origin: this,
      override: ReactionControllerProvider._internal(
        () => create()..postId = postId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<ReactionController, void> createElement() {
    return _ReactionControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ReactionControllerProvider && other.postId == postId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ReactionControllerRef on AutoDisposeNotifierProviderRef<void> {
  /// The parameter `postId` of this provider.
  String get postId;
}

class _ReactionControllerProviderElement
    extends AutoDisposeNotifierProviderElement<ReactionController, void>
    with ReactionControllerRef {
  _ReactionControllerProviderElement(super.provider);

  @override
  String get postId => (origin as ReactionControllerProvider).postId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
