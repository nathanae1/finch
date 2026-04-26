import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/connection_card.dart';
import '../services/follow_service.dart';
import 'identity_provider.dart';
import 'onboarding_provider.dart';
import 'server_provider.dart';
import 'service_providers.dart';

part 'follow_provider.g.dart';

/// Endpoints we currently advertise to peers. Plan 08 shipped only a
/// `direct: 127.0.0.1:<port>` entry, which lets two simulators on one Mac
/// complete the handshake but doesn't work between physical devices on
/// the same WiFi. Plan 09 adds `lan-direct: <LAN_IP>:<port>` so a QR-scan
/// handshake works across two real phones. Plan 11 will add the Tor
/// onion address.
@riverpod
Future<List<Endpoint>> ownEndpoints(OwnEndpointsRef ref) async {
  final port = await ref.watch(httpServerControllerProvider.future);
  if (port == null) return const [];

  final endpoints = <Endpoint>[
    Endpoint(type: 'direct', address: '127.0.0.1:$port'),
  ];
  final lanIp = await _firstLanIPv4();
  if (lanIp != null) {
    endpoints.add(Endpoint(type: 'lan-direct', address: '$lanIp:$port'));
  }
  return endpoints;
}

/// Returns the first non-loopback IPv4 address attached to a UP interface,
/// or `null` if none is available (airplane mode, no WiFi, etc.). Capped
/// at a short timeout so test environments where the platform lookup
/// hangs don't stall the provider.
Future<String?> _firstLanIPv4() async {
  try {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      includeLinkLocal: false,
      type: InternetAddressType.IPv4,
    ).timeout(const Duration(seconds: 1));
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (!addr.isLoopback) return addr.address;
      }
    }
  } catch (_) {
    // NetworkInterface.list is unsupported / slow in some test contexts;
    // treat failure as "no LAN address available."
  }
  return null;
}

/// Singleton [FollowService] for the running app. Constructs the real
/// HTTP transport, wires identity / secret-key lookups, and points the
/// service at the live storage + crypto.
@riverpod
FollowService followService(FollowServiceRef ref) {
  final crypto = ref.watch(cryptoServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  final clock = ref.watch(clockProvider);
  final httpClient = http.Client();
  ref.onDispose(httpClient.close);
  return FollowService(
    crypto: crypto,
    storage: storage,
    clock: clock,
    transport: HandshakeTransport(httpClient),
    identityLookup: storage.getIdentity,
    ownSecretKeyLookup: _loadSecretKey,
    ownEndpointsLookup: () async {
      // Reads the latest endpoints lazily so we don't hold a stale capture.
      return ref.read(ownEndpointsProvider.future);
    },
  );
}

Future<Uint8List?> _loadSecretKey() async {
  const secure = FlutterSecureStorage();
  final encoded = await secure.read(key: kSecretKeyStorageName);
  if (encoded == null) return null;
  return Uint8List.fromList(base64Decode(encoded));
}

/// Convenience: assemble the connection card we share via QR.
@riverpod
Future<ConnectionCard?> ownConnectionCard(OwnConnectionCardRef ref) async {
  final identityAsync = ref.watch(identityControllerProvider);
  final identity = identityAsync.value;
  if (identity == null) return null;
  final endpoints = await ref.watch(ownEndpointsProvider.future);
  return ConnectionCard(pubkey: identity.pubkey, endpoints: endpoints);
}
