import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/models.dart';
import 'identity_provider.dart';
import 'service_providers.dart';

part 'feed_provider.g.dart';

/// Reverse-chronological feed of kind=1 posts from own identity + active
/// follows. Posts with a kind=6 tombstone from the same author are excluded
/// at the storage layer. Plan 09 plugs sync into this — the provider shape
/// doesn't change.
@riverpod
Future<List<Event>> feed(FeedRef ref) async {
  final identity = await ref.watch(identityControllerProvider.future);
  if (identity == null) return const [];
  final storage = ref.watch(storageServiceProvider);
  return storage.getFeedEvents();
}

/// Single event by id, used by the post-detail screen so it doesn't have
/// to re-query the whole feed.
@riverpod
Future<Event?> eventById(EventByIdRef ref, String id) async {
  final storage = ref.watch(storageServiceProvider);
  return storage.getEvent(id);
}

/// Own posts (kind=1, deletes excluded) for the "You"-tab grid.
@riverpod
Future<List<Event>> ownPosts(OwnPostsRef ref) async {
  final identity = await ref.watch(identityControllerProvider.future);
  if (identity == null) return const [];
  final storage = ref.watch(storageServiceProvider);
  return storage.getProfilePosts(identity.pubkey);
}

/// Posts authored by a given pubkey, for other-profile grid.
@riverpod
Future<List<Event>> profilePosts(
  ProfilePostsRef ref,
  String pubkey,
) async {
  final storage = ref.watch(storageServiceProvider);
  return storage.getProfilePosts(pubkey);
}
