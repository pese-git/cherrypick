import 'package:cherrypick/cherrypick.dart';
import 'package:cherrypick_flutter/cherrypick_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:market_pulse/app.dart';
import 'package:market_pulse/core/router/app_routes.dart';

import 'di_harness.dart';

/// The router is resolved from the container like any other dependency.
///
/// These run as widget tests rather than plain unit tests on purpose:
/// `redirect` is evaluated by the `Router` widget's route parser, so a router
/// that is never attached to a tree never runs its guard. Driving it through
/// the real app is both more honest and the only way to see the guard work.
///
/// No test here opens an instrument tab: that would start a periodic feed timer
/// and leave it pending past the end of the test. Tab lifetime is covered in
/// `scope_lifecycle_test.dart`, where it can be closed deterministically.
void main() {
  late TestHarness harness;

  setUp(() async {
    harness = await TestHarness.bootstrap();
  });

  tearDown(TestHarness.tearDown);

  GoRouter router() => CherryPick.openRootScope().resolve<GoRouter>();

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const CherryPickProvider(child: MarketPulseApp()));
    await tester.pumpAndSettle();
  }

  test('the router is a singleton in the root scope', () {
    expect(identical(router(), router()), isTrue);
  });

  testWidgets('a signed-out visitor is bounced to /login, and the destination '
      'is remembered', (tester) async {
    await pumpApp(tester);

    router().go(AppRoutes.symbol('BTCUSD'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in as Europe desk'), findsOneWidget);
    expect(
      find.textContaining('/market/BTCUSD'),
      findsOneWidget,
      reason: 'the guard put the intended location in ?from=',
    );
  });

  testWidgets('signing in resumes the interrupted navigation', (tester) async {
    await pumpApp(tester);

    router().go(AppRoutes.market);
    await tester.pumpAndSettle();
    expect(find.text('Sign in as Europe desk'), findsOneWidget);

    await tester.tap(find.text('Sign in as Europe desk'));
    await tester.pumpAndSettle();

    expect(find.text('INSTRUMENTS'), findsOneWidget);
    expect(find.text('Europe desk'), findsOneWidget);
  });

  testWidgets('signing out sends the workspace back to /login', (tester) async {
    await pumpApp(tester);
    harness.signIn();
    await tester.pumpAndSettle();

    expect(find.text('INSTRUMENTS'), findsOneWidget);

    await harness.workspace.signOut();
    await tester.pumpAndSettle();

    expect(find.text('Sign in as Europe desk'), findsOneWidget);
  });
}
