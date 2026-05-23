import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/types.dart';
import 'service_providers.dart';

part 'identity_provider.g.dart';

/// Loads the local identity row from storage. `null` means onboarding is not
/// complete yet. Router uses this to redirect to the welcome screen.
@riverpod
class IdentityController extends _$IdentityController {
  @override
  Future<Identity?> build() async {
    final storage = ref.watch(storageServiceProvider);
    return storage.getIdentity();
  }

  /// Called by the onboarding flow after writing the identity row. Forces
  /// dependents (the router) to reevaluate.
  void refresh() => ref.invalidateSelf();
}
