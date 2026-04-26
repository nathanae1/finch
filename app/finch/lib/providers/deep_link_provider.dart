import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../utils/connection_card_parser.dart';
import '../utils/deep_link_handler.dart';

part 'deep_link_provider.g.dart';

@riverpod
DeepLinkHandler deepLinkHandler(DeepLinkHandlerRef ref) => DeepLinkHandler();

/// Stream of inbound deep-link invites for the router-level listener to
/// surface as a confirm sheet.
@riverpod
Stream<ParsedInvite> deepLinkInvites(DeepLinkInvitesRef ref) {
  final handler = ref.watch(deepLinkHandlerProvider);
  return handler.invites;
}
