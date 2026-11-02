import 'package:cherrypick/cherrypick.dart';
import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../router/app_router.dart';
import '../router/router_refresh.dart';
import 'workspace_cubit.dart';

/// Binds the router as an ordinary root-scope dependency.
///
/// The router needs the session state to guard routes, and the refresh bridge
/// needs the cubit's stream — both are resolved rather than reached for, so a
/// test can build the same router against a different workspace without
/// touching this module.
class RouterModule extends Module {
  final Talker _talker;

  RouterModule({required Talker talker}) : _talker = talker;

  @override
  void builder(Scope currentScope) {
    // Disposable: closing the root scope cancels the stream subscription.
    bind<GoRouterRefreshStream>()
        .toProvide(
          () => GoRouterRefreshStream(
            currentScope.resolve<WorkspaceCubit>().stream,
          ),
        )
        .singleton();

    bind<GoRouter>()
        .toProvide(
          () => buildAppRouter(
            workspace: currentScope.resolve<WorkspaceCubit>(),
            talker: _talker,
            refresh: currentScope.resolve<GoRouterRefreshStream>(),
          ),
        )
        .singleton();
  }
}
