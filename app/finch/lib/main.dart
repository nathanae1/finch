import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'providers/service_providers.dart';
import 'services/clock.dart';
import 'services/crypto/sodium_crypto_service.dart';
import 'services/storage/database.dart';
import 'services/storage/drift_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = await _initStorageService();
  final cryptoService = await SodiumCryptoService.init();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
        cryptoServiceProvider.overrideWithValue(cryptoService),
      ],
      child: const FinchApp(),
    ),
  );
}

Future<DriftStorageService> _initStorageService() async {
  const storage = FlutterSecureStorage();
  const keyName = 'finch_db_key';

  var dbKey = await storage.read(key: keyName);
  if (dbKey == null) {
    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
    dbKey = keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await storage.write(key: keyName, value: dbKey);
  }

  final db = AppDatabase.encrypted(dbKey);
  return DriftStorageService(db, const SystemClock());
}

class FinchApp extends StatelessWidget {
  const FinchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finch',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Finch'),
        ),
      ),
    );
  }
}
