import 'dart:typed_data';

import 'package:cbor/simple.dart';

/// Pure handler for `/starling/sync/ping/1` — the upgrader's post-dial
/// health gate. Accepts an empty CBOR map, returns an empty CBOR map.
///
/// This protocol is libp2p-only (the shelf HTTP surface doesn't expose
/// it) so there is no shelf adapter — `Libp2pStreamServer` wires the
/// raw inbound stream straight into [buildPingResponseBytes].
Uint8List buildPingResponseBytes(Uint8List _) {
  return Uint8List.fromList(cbor.encode(const <String, dynamic>{}));
}
