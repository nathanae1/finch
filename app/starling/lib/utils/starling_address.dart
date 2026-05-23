import '../services/crypto/crockford_base32.dart';

/// Canonical user-facing address for a Starling identity.
///
/// Derived deterministically from the Ed25519 public key (already stored
/// as a 52-char Crockford base32 string). The address is generated once
/// at user creation and never changes — it does not carry any transport
/// hints, so it stays valid even when the peer's onion or LAN endpoint
/// rotates. Endpoint resolution happens separately (mDNS, stored card).
String starlingAddressOf(String pubkey) => 'starling://$pubkey';

/// Returns the encoded pubkey from a `starling://<pubkey>` URL, or `null`
/// if the input isn't a syntactically valid identity address. Rejects
/// the invite form `starling://connect?card=…` — that's a different scheme
/// and parsed by [parseInvite].
String? pubkeyFromStarlingAddress(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;
  final Uri uri;
  try {
    uri = Uri.parse(trimmed);
  } catch (_) {
    return null;
  }
  if (uri.scheme != 'starling') return null;
  // `starling://connect?card=…` is the invite form, not an identity.
  if (uri.host == 'connect') return null;
  if (uri.host.isEmpty || uri.path.isNotEmpty) return null;
  final candidate = uri.host;
  try {
    final raw = crockfordBase32Decode(candidate);
    if (raw.length != 32) return null;
  } on FormatException {
    return null;
  }
  return candidate;
}

/// Display-friendly truncation: `starling://abcd…wxyz`. Used in places
/// where the full 52-char pubkey would dominate the layout.
String shortStarlingAddress(String pubkey, {int prefix = 4, int suffix = 4}) {
  if (pubkey.length <= prefix + suffix + 1) return starlingAddressOf(pubkey);
  final head = pubkey.substring(0, prefix);
  final tail = pubkey.substring(pubkey.length - suffix);
  return 'starling://$head…$tail';
}
