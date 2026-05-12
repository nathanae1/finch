// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_scanner_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Default to the real method-channel scanner; widget tests override with
/// `MockQrScannerService` via `ProviderScope.overrides`.

@ProviderFor(qrScannerService)
final qrScannerServiceProvider = QrScannerServiceProvider._();

/// Default to the real method-channel scanner; widget tests override with
/// `MockQrScannerService` via `ProviderScope.overrides`.

final class QrScannerServiceProvider
    extends
        $FunctionalProvider<
          QrScannerService,
          QrScannerService,
          QrScannerService
        >
    with $Provider<QrScannerService> {
  /// Default to the real method-channel scanner; widget tests override with
  /// `MockQrScannerService` via `ProviderScope.overrides`.
  QrScannerServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'qrScannerServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$qrScannerServiceHash();

  @$internal
  @override
  $ProviderElement<QrScannerService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  QrScannerService create(Ref ref) {
    return qrScannerService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QrScannerService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QrScannerService>(value),
    );
  }
}

String _$qrScannerServiceHash() => r'188e6d0c1c2f793510b412b4a97e6460fc90383b';
