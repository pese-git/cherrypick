import 'package:cherrypick/cherrypick.dart';

import '../../domain/entity/user_session.dart';
import '../../presentation/session/watchlist_cubit.dart';

/// Bindings that belong to the signed-in user, installed into `session`.
///
/// Everything here dies with the scope on sign-out: [WatchlistCubit] is a
/// [Disposable] singleton whose `dispose()` calls `close()`, so one
/// `closeScope('session')` releases the user's state and every open tab
/// underneath it.
class SessionModule extends Module {
  final UserSession _session;

  SessionModule(this._session);

  @override
  void builder(Scope currentScope) {
    bind<UserSession>().toInstance(_session);

    bind<WatchlistCubit>()
        .toProvide(() => WatchlistCubit(currentScope.resolve<UserSession>()))
        .singleton();
  }
}
