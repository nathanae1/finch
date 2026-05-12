// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads the local identity row from storage. `null` means onboarding is not
/// complete yet. Router uses this to redirect to the welcome screen.

@ProviderFor(IdentityController)
final identityControllerProvider = IdentityControllerProvider._();

/// Loads the local identity row from storage. `null` means onboarding is not
/// complete yet. Router uses this to redirect to the welcome screen.
final class IdentityControllerProvider
    extends $AsyncNotifierProvider<IdentityController, Identity?> {
  /// Loads the local identity row from storage. `null` means onboarding is not
  /// complete yet. Router uses this to redirect to the welcome screen.
  IdentityControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'identityControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$identityControllerHash();

  @$internal
  @override
  IdentityController create() => IdentityController();
}

String _$identityControllerHash() =>
    r'61df561037e1493e1fb81d2f6992e6b901c8a384';

/// Loads the local identity row from storage. `null` means onboarding is not
/// complete yet. Router uses this to redirect to the welcome screen.

abstract class _$IdentityController extends $AsyncNotifier<Identity?> {
  FutureOr<Identity?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Identity?>, Identity?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Identity?>, Identity?>,
              AsyncValue<Identity?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
