// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_paths_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The platform's application-support directory. Starling writes media blobs,
/// indexes, and other non-user-visible state here — not into the user's
/// Documents dir (which is surfaced in the iOS Files app / iTunes file
/// sharing).
///
/// Tests override this with a tmp dir.

@ProviderFor(appSupportDirectory)
final appSupportDirectoryProvider = AppSupportDirectoryProvider._();

/// The platform's application-support directory. Starling writes media blobs,
/// indexes, and other non-user-visible state here — not into the user's
/// Documents dir (which is surfaced in the iOS Files app / iTunes file
/// sharing).
///
/// Tests override this with a tmp dir.

final class AppSupportDirectoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<Directory>,
          Directory,
          FutureOr<Directory>
        >
    with $FutureModifier<Directory>, $FutureProvider<Directory> {
  /// The platform's application-support directory. Starling writes media blobs,
  /// indexes, and other non-user-visible state here — not into the user's
  /// Documents dir (which is surfaced in the iOS Files app / iTunes file
  /// sharing).
  ///
  /// Tests override this with a tmp dir.
  AppSupportDirectoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appSupportDirectoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appSupportDirectoryHash();

  @$internal
  @override
  $FutureProviderElement<Directory> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Directory> create(Ref ref) {
    return appSupportDirectory(ref);
  }
}

String _$appSupportDirectoryHash() =>
    r'103efe5195d364ebdd944f0dedbcd370148fc17c';

/// User-visible export drop. The bundle is written here and then handed to
/// the OS share sheet; the user picks the final destination (Files, iCloud,
/// AirDrop, etc.). Cleared opportunistically — no retention policy yet.

@ProviderFor(exportDirectory)
final exportDirectoryProvider = ExportDirectoryProvider._();

/// User-visible export drop. The bundle is written here and then handed to
/// the OS share sheet; the user picks the final destination (Files, iCloud,
/// AirDrop, etc.). Cleared opportunistically — no retention policy yet.

final class ExportDirectoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<Directory>,
          Directory,
          FutureOr<Directory>
        >
    with $FutureModifier<Directory>, $FutureProvider<Directory> {
  /// User-visible export drop. The bundle is written here and then handed to
  /// the OS share sheet; the user picks the final destination (Files, iCloud,
  /// AirDrop, etc.). Cleared opportunistically — no retention policy yet.
  ExportDirectoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportDirectoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportDirectoryHash();

  @$internal
  @override
  $FutureProviderElement<Directory> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Directory> create(Ref ref) {
    return exportDirectory(ref);
  }
}

String _$exportDirectoryHash() => r'aca60d69b64748f2f2168a661bfcbb124150ba0d';
