import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

import 'daos/events_dao.dart';
import 'daos/follow_requests_dao.dart';
import 'daos/follows_dao.dart';
import 'daos/identity_dao.dart';
import 'daos/media_cache_dao.dart';
import 'daos/outbound_queue_dao.dart';
import 'tables/events_table.dart';
import 'tables/follows_table.dart';
import 'tables/identity_table.dart';
import 'tables/inbound_follow_requests_table.dart';
import 'tables/media_cache_table.dart';
import 'tables/outbound_follow_requests_table.dart';
import 'tables/outbound_queue_table.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    IdentityEntries,
    FollowEntries,
    EventEntries,
    MediaCacheEntries,
    InboundFollowRequestEntries,
    OutboundFollowRequestEntries,
    OutboundQueueEntries,
  ],
  daos: [
    IdentityDao,
    FollowsDao,
    EventsDao,
    MediaCacheDao,
    FollowRequestsDao,
    OutboundQueueDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Production: encrypted file-based DB.
  factory AppDatabase.encrypted(String dbKey) {
    return AppDatabase(_openEncryptedConnection(dbKey));
  }

  /// Tests: in-memory, unencrypted.
  factory AppDatabase.memory() {
    return AppDatabase(NativeDatabase.memory());
  }

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
            'CREATE INDEX idx_events_feed '
            'ON event_entries (created_at DESC)',
          );
          await customStatement(
            'CREATE INDEX idx_events_pubkey '
            'ON event_entries (pubkey, created_at DESC)',
          );
          await customStatement(
            'CREATE INDEX idx_events_ref '
            'ON event_entries (ref_id)',
          );
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await customStatement(
              'ALTER TABLE event_entries ADD COLUMN extensions BLOB',
            );
          }
          if (from < 3) {
            await customStatement(
              'ALTER TABLE identity_entries '
              'ADD COLUMN feed_key_epoch INTEGER NOT NULL DEFAULT 0',
            );
            await customStatement(
              'ALTER TABLE follow_entries '
              'ADD COLUMN feed_key_epoch INTEGER NOT NULL DEFAULT 0',
            );
          }
        },
      );
}

LazyDatabase _openEncryptedConnection(String dbKey) {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'finch.db'));

    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);

    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        rawDb.execute("PRAGMA key = \"x'$dbKey'\";");
        // Fail fast if key is wrong.
        rawDb.execute('SELECT count(*) FROM sqlite_master');
      },
    );
  });
}
