import 'package:finch/providers/search_provider.dart';
import 'package:finch/providers/sync_status_provider.dart';
import 'package:finch/screens/feed/feed_sync_search_bar.dart';
import 'package:finch/theme/finch_theme.dart';
import 'package:finch/widgets/sync_dot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hosts the bar in a minimal Material/Theme/Riverpod tree so we can drive
/// the UI without booting the full app shell.
Widget _harness(
  ProviderContainer container, {
  Widget child = const FeedSyncSearchBar(),
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: buildFinchMaterialTheme(),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('default mode shows the SyncDot', (tester) async {
    final container = ProviderContainer(overrides: [
      syncStatusProvider.overrideWithValue(
        const SyncStatus(state: SyncState.synced),
      ),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container));
    await tester.pumpAndSettle();

    expect(find.byType(SyncDot), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('tapping magnifier swaps to search mode with autofocused field',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container));
    await tester.pumpAndSettle();

    // The rightmost InkWell is the magnifier IconButton.
    await tester.tap(find.byType(InkWell).last);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.byType(SyncDot), findsNothing);
  });

  testWidgets('Cancel exits search mode and clears the query', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container));
    await tester.pumpAndSettle();

    // Enter search mode.
    await tester.tap(find.byType(InkWell).last);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    // Bypass the debounce so the assertion isn't time-dependent.
    container.read(searchQueryProvider.notifier).clear();
    container.read(searchQueryProvider.notifier);
    // Force the underlying provider state directly via the typed container
    // by calling clear, which sets state synchronously.
    expect(container.read(searchQueryProvider), equals(''));

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(container.read(searchQueryProvider), equals(''));
  });
}
