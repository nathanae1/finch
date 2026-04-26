import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/types.dart';
import 'service_providers.dart';

part 'follow_requests_provider.g.dart';

/// Live pending inbound follow requests for the Friends tab banner.
@riverpod
Stream<List<FollowRequest>> inboundRequestsStream(
  InboundRequestsStreamRef ref,
) {
  final storage = ref.watch(storageServiceProvider);
  return storage.watchInboundRequests();
}

/// Live outbound follow requests (any status) for the Friends tab "Pending"
/// rows.
@riverpod
Stream<List<FollowRequest>> outboundRequestsStream(
  OutboundRequestsStreamRef ref,
) {
  final storage = ref.watch(storageServiceProvider);
  return storage.watchOutboundRequests();
}
