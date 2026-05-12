import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'identity_provider.dart';
import 'own_profile_provider.dart';
import 'service_providers.dart';

part 'follow_profile_provider.g.dart';

/// Display name + avatar hash for an arbitrary pubkey, used by post cards
/// and other-profile screens. For own pubkey, dispatches to
/// [ownProfileProvider]; otherwise reads the cached display name from the
/// `follows` row.
class FollowProfileSnapshot {
  const FollowProfileSnapshot({
    required this.displayName,
    this.avatarHash,
  });

  final String displayName;
  final String? avatarHash;
}

@riverpod
Future<FollowProfileSnapshot> followProfile(
  Ref ref,
  String pubkey,
) async {
  // Subscribe synchronously before any await — using `ref` after an await
  // is illegal if the provider was invalidated during the await.
  final identityFuture = ref.watch(identityControllerProvider.future);
  final ownProfileFuture = ref.watch(ownProfileProvider.future);
  final storage = ref.watch(storageServiceProvider);

  final identity = await identityFuture;
  if (identity != null && identity.pubkey == pubkey) {
    final own = await ownProfileFuture;
    return FollowProfileSnapshot(
      displayName: own.displayName,
      avatarHash: own.avatarHash,
    );
  }

  final follow = await storage.getFollow(pubkey);
  final name = follow?.displayName?.trim().isNotEmpty == true
      ? follow!.displayName!.trim()
      : _fallbackName(pubkey);
  return FollowProfileSnapshot(
    displayName: name,
    avatarHash: follow?.avatarHash,
  );
}

/// First name for display (everything before the first whitespace).
String firstNameOf(String displayName) {
  final trimmed = displayName.trim();
  if (trimmed.isEmpty) return 'Friend';
  final ws = trimmed.indexOf(RegExp(r'\s'));
  return ws == -1 ? trimmed : trimmed.substring(0, ws);
}

/// When we have no display name and the pubkey is unknown, render a short
/// hash so the row isn't blank.
String _fallbackName(String pubkey) {
  if (pubkey.length <= 8) return pubkey;
  return '${pubkey.substring(0, 4)}…${pubkey.substring(pubkey.length - 4)}';
}
