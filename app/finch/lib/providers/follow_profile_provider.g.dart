// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$followProfileHash() => r'ba7ba13a2b997fec01318cc71002726270e4c01e';

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

/// See also [followProfile].
@ProviderFor(followProfile)
const followProfileProvider = FollowProfileFamily();

/// See also [followProfile].
class FollowProfileFamily extends Family<AsyncValue<FollowProfileSnapshot>> {
  /// See also [followProfile].
  const FollowProfileFamily();

  /// See also [followProfile].
  FollowProfileProvider call(String pubkey) {
    return FollowProfileProvider(pubkey);
  }

  @override
  FollowProfileProvider getProviderOverride(
    covariant FollowProfileProvider provider,
  ) {
    return call(provider.pubkey);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'followProfileProvider';
}

/// See also [followProfile].
class FollowProfileProvider
    extends AutoDisposeFutureProvider<FollowProfileSnapshot> {
  /// See also [followProfile].
  FollowProfileProvider(String pubkey)
    : this._internal(
        (ref) => followProfile(ref as FollowProfileRef, pubkey),
        from: followProfileProvider,
        name: r'followProfileProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$followProfileHash,
        dependencies: FollowProfileFamily._dependencies,
        allTransitiveDependencies:
            FollowProfileFamily._allTransitiveDependencies,
        pubkey: pubkey,
      );

  FollowProfileProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.pubkey,
  }) : super.internal();

  final String pubkey;

  @override
  Override overrideWith(
    FutureOr<FollowProfileSnapshot> Function(FollowProfileRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FollowProfileProvider._internal(
        (ref) => create(ref as FollowProfileRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        pubkey: pubkey,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<FollowProfileSnapshot> createElement() {
    return _FollowProfileProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FollowProfileProvider && other.pubkey == pubkey;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, pubkey.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FollowProfileRef on AutoDisposeFutureProviderRef<FollowProfileSnapshot> {
  /// The parameter `pubkey` of this provider.
  String get pubkey;
}

class _FollowProfileProviderElement
    extends AutoDisposeFutureProviderElement<FollowProfileSnapshot>
    with FollowProfileRef {
  _FollowProfileProviderElement(super.provider);

  @override
  String get pubkey => (origin as FollowProfileProvider).pubkey;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
