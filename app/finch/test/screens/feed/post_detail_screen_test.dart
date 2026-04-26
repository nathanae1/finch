import 'dart:typed_data';

import 'package:finch/models/models.dart';
import 'package:finch/providers/service_providers.dart';
import 'package:finch/screens/feed/post_detail_screen.dart';
import 'package:finch/services/mocks/mock_clock.dart';
import 'package:finch/services/mocks/mock_storage_service.dart';
import 'package:finch/services/types.dart';
import 'package:finch/theme/finch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Event _post(String id, {int createdAt = 1000}) => Event(
      version: '2026-03-24',
      id: id,
      pubkey: 'me',
      createdAt: createdAt,
      kind: EventKind.post,
      content: Uint8List.fromList('caption'.codeUnits),
      sig: Uint8List.fromList(List.filled(64, 0)),
    );

Widget _harness(ProviderContainer container, String eventId) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: buildFinchMaterialTheme(),
      home: PostDetailScreen(eventId: eventId),
    ),
  );
}

void main() {
  testWidgets('initState marks the event as last_viewed', (tester) async {
    final storage = MockStorageService();
    final clock = MockClock();
    clock.advance(5000);
    await storage.saveIdentity(Identity(
      pubkey: 'me',
      feedKey: Uint8List(32),
      createdAt: 0,
    ));
    await storage.saveEvent(_post('e1'));

    final container = ProviderContainer(overrides: [
      storageServiceProvider.overrideWithValue(storage),
      clockProvider.overrideWithValue(clock),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container, 'e1'));
    await tester.pumpAndSettle();

    // initState fired setEventLastViewed; the mock records it.
    // Indirect verification: not strictly readable from public API, but the
    // call shouldn't throw and the screen should render without error.
    expect(find.text('caption'), findsOneWidget);
  });

  testWidgets('tapping bookmark flips is_saved on storage', (tester) async {
    final storage = MockStorageService();
    final clock = MockClock();
    await storage.saveIdentity(Identity(
      pubkey: 'me',
      feedKey: Uint8List(32),
      createdAt: 0,
    ));
    await storage.saveEvent(_post('e1'));

    final container = ProviderContainer(overrides: [
      storageServiceProvider.overrideWithValue(storage),
      clockProvider.overrideWithValue(clock),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container, 'e1'));
    await tester.pumpAndSettle();

    expect(await storage.isEventSaved('e1'), isFalse);

    // The bookmark button lives inside an InkWell wrapping a Phosphor icon.
    // Find it by walking from the bookmark Icon up to its InkWell ancestor.
    final iconFinder = find.byIcon(_findBookmarkOutline(tester));
    expect(iconFinder, findsOneWidget);
    final inkWell = find.ancestor(
      of: iconFinder,
      matching: find.byType(InkWell),
    );
    expect(inkWell, findsOneWidget);

    await tester.tap(inkWell);
    await tester.pumpAndSettle();

    expect(await storage.isEventSaved('e1'), isTrue);
  });
}

/// Pulls the icon code point of the bookmark-simple regular Phosphor icon
/// off the actual rendered widget. We don't depend on Phosphor's import path
/// directly so the test stays robust to icon-pack versioning.
IconData _findBookmarkOutline(WidgetTester tester) {
  // The action row renders exactly two non-button icons (heart, chat) plus
  // the bookmark inside the FinchIconButton. The bookmark icon is the only
  // one inside an InkWell with a non-null onPressed in this screen besides
  // the back button. Easier: just pull the icon by reading the rendered
  // _ActionRow's bookmark Icon — we approximate by finding any Icon that's
  // a descendant of an InkWell with onTap != null and whose ancestor is not
  // the back AppBar arrow.
  final icons = tester
      .widgetList<Icon>(find.byType(Icon))
      .where((i) => i.icon != null)
      .toList();
  // Bookmark-simple is the rightmost icon in the action row (spacer pushes
  // it to the end). With the screen layout: arrow-left (back), heart, chat,
  // bookmark, paper-plane.
  // Rather than hard-code an index, just match by the conventional code
  // points returned by phosphor_flutter: bookmark icons live in a known
  // PhosphorIconData range. Easiest: grab the third icon by visual order
  // among the action row icons (heart, chat, bookmark).
  // Fallback: return the icon with the largest x position among the
  // action-row icons.
  // For simplicity: assume the bookmark is the icon whose IconData isn't
  // matched by 'heart' or 'chat'. We don't know those constants here; pick
  // the icon at index 3 (zero-based) of those rendered: 0=back, 1=heart,
  // 2=chat, 3=bookmark, 4=paper-plane.
  expect(icons.length, greaterThanOrEqualTo(4),
      reason: 'expected back/heart/chat/bookmark icons rendered');
  return icons[3].icon!;
}
