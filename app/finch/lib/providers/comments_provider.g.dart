// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comments_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$commentsHash() => r'ba792dec573db44089f8e8683442c2d4629cde73';

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

/// Comments (kind=4) on the post identified by [postId], ordered ASC by
/// `created_at`, filtered to authors the local viewer follows or is
/// themselves. Tombstoned comments (kind=6 referencing the comment id by
/// the same author) are excluded.
///
/// Storage holds every received comment regardless of follow status — the
/// filter is at the read layer so following someone retroactively reveals
/// their old comments without a backfill.
///
/// Copied from [comments].
@ProviderFor(comments)
const commentsProvider = CommentsFamily();

/// Comments (kind=4) on the post identified by [postId], ordered ASC by
/// `created_at`, filtered to authors the local viewer follows or is
/// themselves. Tombstoned comments (kind=6 referencing the comment id by
/// the same author) are excluded.
///
/// Storage holds every received comment regardless of follow status — the
/// filter is at the read layer so following someone retroactively reveals
/// their old comments without a backfill.
///
/// Copied from [comments].
class CommentsFamily extends Family<AsyncValue<List<Event>>> {
  /// Comments (kind=4) on the post identified by [postId], ordered ASC by
  /// `created_at`, filtered to authors the local viewer follows or is
  /// themselves. Tombstoned comments (kind=6 referencing the comment id by
  /// the same author) are excluded.
  ///
  /// Storage holds every received comment regardless of follow status — the
  /// filter is at the read layer so following someone retroactively reveals
  /// their old comments without a backfill.
  ///
  /// Copied from [comments].
  const CommentsFamily();

  /// Comments (kind=4) on the post identified by [postId], ordered ASC by
  /// `created_at`, filtered to authors the local viewer follows or is
  /// themselves. Tombstoned comments (kind=6 referencing the comment id by
  /// the same author) are excluded.
  ///
  /// Storage holds every received comment regardless of follow status — the
  /// filter is at the read layer so following someone retroactively reveals
  /// their old comments without a backfill.
  ///
  /// Copied from [comments].
  CommentsProvider call(String postId) {
    return CommentsProvider(postId);
  }

  @override
  CommentsProvider getProviderOverride(covariant CommentsProvider provider) {
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
  String? get name => r'commentsProvider';
}

/// Comments (kind=4) on the post identified by [postId], ordered ASC by
/// `created_at`, filtered to authors the local viewer follows or is
/// themselves. Tombstoned comments (kind=6 referencing the comment id by
/// the same author) are excluded.
///
/// Storage holds every received comment regardless of follow status — the
/// filter is at the read layer so following someone retroactively reveals
/// their old comments without a backfill.
///
/// Copied from [comments].
class CommentsProvider extends AutoDisposeFutureProvider<List<Event>> {
  /// Comments (kind=4) on the post identified by [postId], ordered ASC by
  /// `created_at`, filtered to authors the local viewer follows or is
  /// themselves. Tombstoned comments (kind=6 referencing the comment id by
  /// the same author) are excluded.
  ///
  /// Storage holds every received comment regardless of follow status — the
  /// filter is at the read layer so following someone retroactively reveals
  /// their old comments without a backfill.
  ///
  /// Copied from [comments].
  CommentsProvider(String postId)
    : this._internal(
        (ref) => comments(ref as CommentsRef, postId),
        from: commentsProvider,
        name: r'commentsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$commentsHash,
        dependencies: CommentsFamily._dependencies,
        allTransitiveDependencies: CommentsFamily._allTransitiveDependencies,
        postId: postId,
      );

  CommentsProvider._internal(
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
    FutureOr<List<Event>> Function(CommentsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CommentsProvider._internal(
        (ref) => create(ref as CommentsRef),
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
  AutoDisposeFutureProviderElement<List<Event>> createElement() {
    return _CommentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CommentsProvider && other.postId == postId;
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
mixin CommentsRef on AutoDisposeFutureProviderRef<List<Event>> {
  /// The parameter `postId` of this provider.
  String get postId;
}

class _CommentsProviderElement
    extends AutoDisposeFutureProviderElement<List<Event>>
    with CommentsRef {
  _CommentsProviderElement(super.provider);

  @override
  String get postId => (origin as CommentsProvider).postId;
}

String _$commentControllerHash() => r'59ed1fec8e92bef756f69fff3a37befa8d9bc03a';

abstract class _$CommentController extends BuildlessAutoDisposeNotifier<void> {
  late final String postId;

  void build(String postId);
}

/// Create / delete a comment on [postId]. Invalidates [commentsProvider]
/// for the same post on every successful action so the post detail
/// screen rebuilds.
///
/// Copied from [CommentController].
@ProviderFor(CommentController)
const commentControllerProvider = CommentControllerFamily();

/// Create / delete a comment on [postId]. Invalidates [commentsProvider]
/// for the same post on every successful action so the post detail
/// screen rebuilds.
///
/// Copied from [CommentController].
class CommentControllerFamily extends Family<void> {
  /// Create / delete a comment on [postId]. Invalidates [commentsProvider]
  /// for the same post on every successful action so the post detail
  /// screen rebuilds.
  ///
  /// Copied from [CommentController].
  const CommentControllerFamily();

  /// Create / delete a comment on [postId]. Invalidates [commentsProvider]
  /// for the same post on every successful action so the post detail
  /// screen rebuilds.
  ///
  /// Copied from [CommentController].
  CommentControllerProvider call(String postId) {
    return CommentControllerProvider(postId);
  }

  @override
  CommentControllerProvider getProviderOverride(
    covariant CommentControllerProvider provider,
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
  String? get name => r'commentControllerProvider';
}

/// Create / delete a comment on [postId]. Invalidates [commentsProvider]
/// for the same post on every successful action so the post detail
/// screen rebuilds.
///
/// Copied from [CommentController].
class CommentControllerProvider
    extends AutoDisposeNotifierProviderImpl<CommentController, void> {
  /// Create / delete a comment on [postId]. Invalidates [commentsProvider]
  /// for the same post on every successful action so the post detail
  /// screen rebuilds.
  ///
  /// Copied from [CommentController].
  CommentControllerProvider(String postId)
    : this._internal(
        () => CommentController()..postId = postId,
        from: commentControllerProvider,
        name: r'commentControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$commentControllerHash,
        dependencies: CommentControllerFamily._dependencies,
        allTransitiveDependencies:
            CommentControllerFamily._allTransitiveDependencies,
        postId: postId,
      );

  CommentControllerProvider._internal(
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
  void runNotifierBuild(covariant CommentController notifier) {
    return notifier.build(postId);
  }

  @override
  Override overrideWith(CommentController Function() create) {
    return ProviderOverride(
      origin: this,
      override: CommentControllerProvider._internal(
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
  AutoDisposeNotifierProviderElement<CommentController, void> createElement() {
    return _CommentControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CommentControllerProvider && other.postId == postId;
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
mixin CommentControllerRef on AutoDisposeNotifierProviderRef<void> {
  /// The parameter `postId` of this provider.
  String get postId;
}

class _CommentControllerProviderElement
    extends AutoDisposeNotifierProviderElement<CommentController, void>
    with CommentControllerRef {
  _CommentControllerProviderElement(super.provider);

  @override
  String get postId => (origin as CommentControllerProvider).postId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
