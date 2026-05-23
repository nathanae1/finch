// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mediaService)
final mediaServiceProvider = MediaServiceProvider._();

final class MediaServiceProvider
    extends $FunctionalProvider<MediaService, MediaService, MediaService>
    with $Provider<MediaService> {
  MediaServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaServiceHash();

  @$internal
  @override
  $ProviderElement<MediaService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MediaService create(Ref ref) {
    return mediaService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MediaService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MediaService>(value),
    );
  }
}

String _$mediaServiceHash() => r'216da747c7ae5b502b6461c5b36690d85cad9d0d';

/// Lazily fetches media from peers when the local cache misses. Used by
/// `EncryptedImage` as a fallback path.

@ProviderFor(remoteMediaFetcher)
final remoteMediaFetcherProvider = RemoteMediaFetcherProvider._();

/// Lazily fetches media from peers when the local cache misses. Used by
/// `EncryptedImage` as a fallback path.

final class RemoteMediaFetcherProvider
    extends
        $FunctionalProvider<
          RemoteMediaFetcher,
          RemoteMediaFetcher,
          RemoteMediaFetcher
        >
    with $Provider<RemoteMediaFetcher> {
  /// Lazily fetches media from peers when the local cache misses. Used by
  /// `EncryptedImage` as a fallback path.
  RemoteMediaFetcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remoteMediaFetcherProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remoteMediaFetcherHash();

  @$internal
  @override
  $ProviderElement<RemoteMediaFetcher> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RemoteMediaFetcher create(Ref ref) {
    return remoteMediaFetcher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RemoteMediaFetcher value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RemoteMediaFetcher>(value),
    );
  }
}

String _$remoteMediaFetcherHash() =>
    r'f88261683fcedd05ed3aff28c1853e115df7d556';

@ProviderFor(exportService)
final exportServiceProvider = ExportServiceProvider._();

final class ExportServiceProvider
    extends $FunctionalProvider<ExportService, ExportService, ExportService>
    with $Provider<ExportService> {
  ExportServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportServiceHash();

  @$internal
  @override
  $ProviderElement<ExportService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ExportService create(Ref ref) {
    return exportService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExportService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExportService>(value),
    );
  }
}

String _$exportServiceHash() => r'3682e1f13873c20ce39397de39cd132b01234217';
