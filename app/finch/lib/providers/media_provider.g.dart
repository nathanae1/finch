// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$mediaServiceHash() => r'98153b0e73cd589dec122dd7effc0090bec048a8';

/// See also [mediaService].
@ProviderFor(mediaService)
final mediaServiceProvider = AutoDisposeProvider<MediaService>.internal(
  mediaService,
  name: r'mediaServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$mediaServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MediaServiceRef = AutoDisposeProviderRef<MediaService>;
String _$remoteMediaFetcherHash() =>
    r'f4dbb238abf3f263b7df5c6bfb4ea946dd7379f0';

/// Lazily fetches media from peers when the local cache misses. Used by
/// `EncryptedImage` as a fallback path.
///
/// Copied from [remoteMediaFetcher].
@ProviderFor(remoteMediaFetcher)
final remoteMediaFetcherProvider =
    AutoDisposeProvider<RemoteMediaFetcher>.internal(
      remoteMediaFetcher,
      name: r'remoteMediaFetcherProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$remoteMediaFetcherHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RemoteMediaFetcherRef = AutoDisposeProviderRef<RemoteMediaFetcher>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
