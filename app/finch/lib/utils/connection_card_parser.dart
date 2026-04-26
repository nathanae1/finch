import 'dart:convert';
import 'dart:typed_data';

import '../models/connection_card.dart';
import '../services/crypto/crockford_base32.dart';

/// Result of parsing scanned/pasted invite text.
sealed class ParsedInvite {
  const ParsedInvite();
}

class ValidInvite extends ParsedInvite {
  const ValidInvite(this.card);
  final ConnectionCard card;
}

class InvalidInvite extends ParsedInvite {
  const InvalidInvite(this.reason);
  final String reason;
}

/// Parses a Finch invite. Accepts the full deep-link form
/// `finch://connect?card=<base64url>` or a bare base64url payload of the
/// CBOR-encoded [ConnectionCard]. Whitespace is stripped before parsing.
ParsedInvite parseInvite(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    return const InvalidInvite('empty input');
  }

  String b64;
  final hasScheme = trimmed.contains('://');
  if (hasScheme) {
    final Uri uri;
    try {
      uri = Uri.parse(trimmed);
    } catch (_) {
      return const InvalidInvite('not a valid URL');
    }
    if (uri.scheme != 'finch' || uri.host != 'connect') {
      return const InvalidInvite('not a finch://connect URL');
    }
    final card = uri.queryParameters['card'];
    if (card == null || card.isEmpty) {
      return const InvalidInvite('missing card parameter');
    }
    b64 = card;
  } else {
    b64 = trimmed;
  }

  final Uint8List bytes;
  try {
    bytes = base64Url.decode(_padBase64(b64));
  } catch (_) {
    return const InvalidInvite('invite is not valid base64url');
  }

  final ConnectionCard card;
  try {
    card = ConnectionCard.fromBytes(bytes);
  } catch (_) {
    return const InvalidInvite('invite payload is not a valid connection card');
  }

  if (card.pubkey.isEmpty) {
    return const InvalidInvite('invite is missing a pubkey');
  }
  try {
    final raw = crockfordBase32Decode(card.pubkey);
    if (raw.length != 32) {
      return const InvalidInvite('invite has a malformed pubkey');
    }
  } on FormatException {
    return const InvalidInvite('invite has a malformed pubkey');
  }

  return ValidInvite(card);
}

/// Builds the canonical share URL for [card]: `finch://connect?card=<b64url>`.
String inviteUrlFor(ConnectionCard card) {
  final encoded = base64Url.encode(card.toBytes()).replaceAll('=', '');
  return 'finch://connect?card=$encoded';
}

String _padBase64(String input) {
  final remainder = input.length % 4;
  if (remainder == 0) return input;
  return input + '=' * (4 - remainder);
}
