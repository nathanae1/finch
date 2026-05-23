import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/identity_table.dart';

part 'identity_dao.g.dart';

@DriftAccessor(tables: [IdentityEntries])
class IdentityDao extends DatabaseAccessor<AppDatabase>
    with _$IdentityDaoMixin {
  IdentityDao(super.db);

  Future<IdentityEntry?> getIdentity() =>
      (select(identityEntries)..limit(1)).getSingleOrNull();

  Future<void> upsertIdentity(IdentityEntriesCompanion entry) =>
      into(identityEntries).insertOnConflictUpdate(entry);
}
