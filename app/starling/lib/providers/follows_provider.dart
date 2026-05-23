import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/types.dart';
import 'service_providers.dart';

part 'follows_provider.g.dart';

/// All active follows. Plan 08 wires the real management UI; Plan 06 just
/// needs the list (count + per-pubkey lookups for profile rendering).
@riverpod
Future<List<Follow>> follows(Ref ref) async {
  final storage = ref.watch(storageServiceProvider);
  return storage.getFollows();
}

/// Live stream of active follows. Friends-tab UI watches this so accept /
/// unfollow operations re-render without manual invalidation.
@riverpod
Stream<List<Follow>> followsStream(Ref ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.watchFollows();
}
