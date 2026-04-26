import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/crypto/crockford_base32.dart';
import '../services/types.dart';
import 'identity_provider.dart';
import 'service_providers.dart';

part 'onboarding_provider.g.dart';

/// Where the Ed25519 secret key lives in the OS keychain. Referenced by
/// `main.dart` to hydrate `PairwiseContentKeyService` on app launch.
const kSecretKeyStorageName = 'finch_secret_key';

/// Transient session-level state built up during onboarding — the generated
/// recovery phrase that the user hasn't yet confirmed they've written down.
/// Cleared once they tap "I wrote it down" on the recovery screen.
class OnboardingSession {
  const OnboardingSession({this.recoveryPhrase});
  final List<String>? recoveryPhrase;

  OnboardingSession copyWith({List<String>? recoveryPhrase}) =>
      OnboardingSession(recoveryPhrase: recoveryPhrase ?? this.recoveryPhrase);
}

@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  OnboardingSession build() => const OnboardingSession();

  /// Generates keypair + feed key, derives recovery phrase, writes the identity
  /// row and stashes the secret key in secure storage. Returns the generated
  /// recovery phrase (also cached in session state so the Recovery screen can
  /// read it without re-deriving).
  Future<List<String>> createIdentity() async {
    final crypto = ref.read(cryptoServiceProvider);
    final storage = ref.read(storageServiceProvider);
    final clock = ref.read(clockProvider);

    // Seed → keypair → phrase. Round-tripping through recoverFromPhrase keeps
    // the pubkey matched to what a future restore would derive.
    final seed = crypto.randomBytes(32);
    final phrase = await crypto.deriveRecoveryPhrase(seed);
    final keypair = await crypto.recoverFromPhrase(phrase);

    final feedKey = crypto.randomBytes(32);

    await _writeSecretKey(keypair.secretKey);

    final identity = Identity(
      pubkey: crockfordBase32Encode(keypair.publicKey),
      feedKey: feedKey,
      feedKeyEpoch: 0,
      createdAt: clock.nowUnixSeconds(),
    );
    await storage.saveIdentity(identity);

    state = state.copyWith(recoveryPhrase: phrase);
    ref.read(identityControllerProvider.notifier).refresh();
    return phrase;
  }

  /// Restores an identity from a user-supplied 24-word recovery phrase. Writes
  /// the identity row + secret key. Throws if the phrase is invalid.
  Future<void> restoreIdentity(List<String> phrase) async {
    final crypto = ref.read(cryptoServiceProvider);
    final storage = ref.read(storageServiceProvider);
    final clock = ref.read(clockProvider);

    final keypair = await crypto.recoverFromPhrase(phrase);
    // No feed key survives the recovery phrase; start a fresh one.
    final feedKey = crypto.randomBytes(32);

    await _writeSecretKey(keypair.secretKey);

    final identity = Identity(
      pubkey: crockfordBase32Encode(keypair.publicKey),
      feedKey: feedKey,
      feedKeyEpoch: 0,
      createdAt: clock.nowUnixSeconds(),
    );
    await storage.saveIdentity(identity);
    ref.read(identityControllerProvider.notifier).refresh();
  }

  /// Clears the in-memory recovery phrase once the user has acknowledged it.
  void clearRecoveryPhrase() {
    state = const OnboardingSession();
  }

  Future<void> _writeSecretKey(Uint8List secretKey) async {
    const secure = FlutterSecureStorage();
    await secure.write(
      key: kSecretKeyStorageName,
      value: base64Encode(secretKey),
    );
  }
}

