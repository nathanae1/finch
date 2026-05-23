import 'package:starling/services/storage/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  test('database creates successfully', () async {
    // Just accessing a table triggers schema creation.
    final identity = await db.identityDao.getIdentity();
    expect(identity, isNull);
  });

  test('all 7 tables exist', () async {
    final result = await db.customSelect(
      "SELECT name FROM sqlite_master WHERE type='table' "
      "AND name NOT LIKE 'sqlite_%'",
    ).get();
    final tableNames = result.map((r) => r.data['name'] as String).toSet();

    expect(tableNames, containsAll([
      'identity_entries',
      'follow_entries',
      'event_entries',
      'media_cache_entries',
      'inbound_follow_request_entries',
      'outbound_follow_request_entries',
      'outbound_queue_entries',
    ]));
  });

  test('event indexes exist', () async {
    final result = await db.customSelect(
      "SELECT name FROM sqlite_master WHERE type='index' "
      "AND name LIKE 'idx_events_%'",
    ).get();
    final indexNames = result.map((r) => r.data['name'] as String).toSet();

    expect(indexNames, containsAll([
      'idx_events_feed',
      'idx_events_pubkey',
      'idx_events_ref',
    ]));
  });
}
