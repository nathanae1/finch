import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/models.dart';
import 'identity_provider.dart';
import 'service_providers.dart';

part 'events_provider.g.dart';

/// All events authored by the current identity, newest-first via storage's
/// default ordering. Plan 06 will layer a richer feed query on top; this
/// minimal provider exists so the post-publish path can invalidate it.
@riverpod
Future<List<Event>> ownEvents(Ref ref) async {
  final identity = await ref.watch(identityControllerProvider.future);
  if (identity == null) return const [];
  final storage = ref.watch(storageServiceProvider);
  return storage.getEvents(pubkey: identity.pubkey);
}
