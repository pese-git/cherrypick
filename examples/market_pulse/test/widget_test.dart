import 'package:cherrypick_flutter/cherrypick_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_pulse/app.dart';

import 'di_harness.dart';

/// Smoke test of the sign-in transition.
///
/// No instrument is opened on purpose: opening one starts a periodic feed timer
/// that would still be pending when the test ends.
void main() {
  setUp(TestHarness.bootstrap);
  tearDown(TestHarness.tearDown);

  testWidgets('signing in swaps the login gate for the workspace', (
    tester,
  ) async {
    await tester.pumpWidget(const CherryPickProvider(child: MarketPulseApp()));
    await tester.pumpAndSettle();

    // The guard bounced the initial /market location to /login.
    expect(find.text('Sign in as Europe desk'), findsOneWidget);

    await tester.tap(find.text('Sign in as Europe desk'));
    await tester.pumpAndSettle();

    expect(find.text('INSTRUMENTS'), findsOneWidget);
    expect(find.text('Europe desk'), findsOneWidget);
    expect(find.text('BTCUSD'), findsOneWidget);
  });
}
