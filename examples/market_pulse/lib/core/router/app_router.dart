import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../presentation/market/market_tab_page.dart';
import '../../presentation/market/market_tabs_view.dart';
import '../../presentation/session/login_page.dart';
import '../../presentation/shell/market_pulse_shell.dart';
import '../di/workspace_cubit.dart';
import 'app_routes.dart';
import 'router_refresh.dart';

/// Builds the app's router.
///
/// Two things are worth reading closely:
///
/// 1. **The guard is a match on `Option<UserSession>`.** There is no `isLoggedIn`
///    boolean to drift out of sync — the same value that decides whether the
///    session scope exists decides whether the workspace is reachable.
/// 2. **A URL opens a DI scope.** `/market/BTCUSD` is not just a screen, it is a
///    request for the subscope `session.market.BTCUSD`. Opening that link in a
///    fresh browser tab signs in first, then builds the scope — the address bar
///    is a control surface for the dependency graph.
GoRouter buildAppRouter({
  required WorkspaceCubit workspace,
  required Talker talker,
  required GoRouterRefreshStream refresh,
  String initialLocation = AppRoutes.market,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = workspace.state.isSignedIn;
      final goingToLogin = state.matchedLocation == AppRoutes.login;

      if (!signedIn && !goingToLogin) {
        // Remember where they were headed so sign-in can finish the journey.
        return Uri(
          path: AppRoutes.login,
          queryParameters: {AppRoutes.fromParam: state.uri.toString()},
        ).toString();
      }

      if (signedIn && goingToLogin) {
        return state.uri.queryParameters[AppRoutes.fromParam] ??
            AppRoutes.market;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) =>
            LoginPage(from: state.uri.queryParameters[AppRoutes.fromParam]),
      ),
      GoRoute(
        path: AppRoutes.logs,
        builder: (context, state) => TalkerScreen(talker: talker),
      ),
      // The workspace chrome — watchlist, top bar, Inspector — is built once
      // and survives navigation between instruments.
      ShellRoute(
        builder: (context, state, child) => MarketPulseShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.market,
            builder: (context, state) => const MarketTabsView(),
            routes: [
              GoRoute(
                path: ':symbol',
                builder: (context, state) =>
                    MarketTabPage(symbol: state.pathParameters['symbol']!),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
