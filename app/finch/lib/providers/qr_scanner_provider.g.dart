// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_scanner_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$qrScannerServiceHash() => r'525d54bd8cbc1e08e8463ffb0922da3224d08b2c';

/// Default to the real method-channel scanner; widget tests override with
/// `MockQrScannerService` via `ProviderScope.overrides`.
///
/// Copied from [qrScannerService].
@ProviderFor(qrScannerService)
final qrScannerServiceProvider = AutoDisposeProvider<QrScannerService>.internal(
  qrScannerService,
  name: r'qrScannerServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$qrScannerServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef QrScannerServiceRef = AutoDisposeProviderRef<QrScannerService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
