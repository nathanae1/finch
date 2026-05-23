import 'package:app_links/app_links.dart';

import 'connection_card_parser.dart';

/// Wraps the platform deep-link stream and parses incoming
/// `starling://connect?card=...` URIs into [ParsedInvite] events. URIs that
/// don't match the scheme/host are dropped silently.
class DeepLinkHandler {
  DeepLinkHandler({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  /// Stream of parsed invites from cold-start and runtime deep-link events.
  Stream<ParsedInvite> get invites async* {
    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      final parsed = _parse(initial);
      if (parsed != null) yield parsed;
    }
    yield* _appLinks.uriLinkStream
        .map(_parse)
        .where((event) => event != null)
        .cast<ParsedInvite>();
  }

  ParsedInvite? _parse(Uri uri) {
    if (uri.scheme != 'starling' || uri.host != 'connect') return null;
    return parseInvite(uri.toString());
  }
}
