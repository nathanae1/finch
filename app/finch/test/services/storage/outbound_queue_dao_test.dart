import 'dart:typed_data';

import 'package:finch/services/storage/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  test('enqueues and dequeues by target', () async {
    await db.outboundQueueDao.enqueue(
      OutboundQueueEntriesCompanion.insert(
        targetPubkey: 'target-1',
        eventBlob: Uint8List.fromList([10, 20, 30]),
        createdAt: 1000,
      ),
    );
    await db.outboundQueueDao.enqueue(
      OutboundQueueEntriesCompanion.insert(
        targetPubkey: 'target-2',
        eventBlob: Uint8List.fromList([40, 50]),
        createdAt: 1001,
      ),
    );

    final target1 = await db.outboundQueueDao.dequeue('target-1');
    expect(target1, hasLength(1));
    expect(target1.first.targetPubkey, equals('target-1'));

    final target2 = await db.outboundQueueDao.dequeue('target-2');
    expect(target2, hasLength(1));
  });

  test('increments retry count', () async {
    await db.outboundQueueDao.enqueue(
      OutboundQueueEntriesCompanion.insert(
        targetPubkey: 'target-1',
        eventBlob: Uint8List.fromList([1]),
        createdAt: 1000,
      ),
    );

    final items = await db.outboundQueueDao.dequeue('target-1');
    expect(items.first.retryCount, equals(0));

    await db.outboundQueueDao.incrementRetry(items.first.id);

    final updated = await db.outboundQueueDao.dequeue('target-1');
    expect(updated.first.retryCount, equals(1));
  });

  test('removes from queue', () async {
    await db.outboundQueueDao.enqueue(
      OutboundQueueEntriesCompanion.insert(
        targetPubkey: 'target-1',
        eventBlob: Uint8List.fromList([1]),
        createdAt: 1000,
      ),
    );

    final items = await db.outboundQueueDao.dequeue('target-1');
    await db.outboundQueueDao.removeFromQueue(items.first.id);

    final remaining = await db.outboundQueueDao.dequeue('target-1');
    expect(remaining, isEmpty);
  });
}
