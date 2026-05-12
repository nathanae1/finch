import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/event_kind.dart';
import 'identity_provider.dart';
import 'service_providers.dart';

part 'own_profile_provider.g.dart';

/// What the "You" tab + post cards show as the device owner's identity.
/// Sourced from the latest kind=2 (profile) event when one exists.
class OwnProfileSnapshot {
  const OwnProfileSnapshot({
    required this.displayName,
    this.bio,
    this.avatarHash,
  });

  final String displayName;
  final String? bio;
  final String? avatarHash;
}

/// Reads the latest kind=2 event for own pubkey and decodes its JSON content
/// into a profile snapshot. Falls back to "You" with no avatar when no
/// profile event has been written yet (the Plan 04 onboarding flow currently
/// does not write one — see the project README and Plan 04 spec for the
/// kind=2 contract; a future profile-edit screen, Plan 15, will create it).
@riverpod
Future<OwnProfileSnapshot> ownProfile(Ref ref) async {
  final identity = await ref.watch(identityControllerProvider.future);
  if (identity == null) {
    return const OwnProfileSnapshot(displayName: 'You');
  }
  final storage = ref.watch(storageServiceProvider);
  final events = await storage.getEvents(pubkey: identity.pubkey);
  final latestProfile = events
      .where((e) => e.kind == EventKind.profile)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  if (latestProfile.isEmpty) {
    return const OwnProfileSnapshot(displayName: 'You');
  }

  final raw = utf8.decode(latestProfile.first.content, allowMalformed: true);
  try {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return OwnProfileSnapshot(
      displayName: (map['name'] as String?)?.trim().isNotEmpty == true
          ? (map['name'] as String).trim()
          : 'You',
      bio: (map['bio'] as String?)?.trim().isNotEmpty == true
          ? (map['bio'] as String).trim()
          : null,
      avatarHash: (map['avatar_hash'] as String?)?.trim().isNotEmpty == true
          ? (map['avatar_hash'] as String).trim()
          : null,
    );
  } catch (_) {
    // Malformed kind=2 — defensively show "You" rather than crashing the tab.
    return const OwnProfileSnapshot(displayName: 'You');
  }
}
