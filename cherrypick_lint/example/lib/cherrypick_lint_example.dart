// A small, deliberately rule-clean CherryPick setup. Its job is to show what
// enabling cherrypick_lint looks like from a consumer's side (see
// analysis_options.yaml in this package) — `dart analyze` here must stay
// quiet.
//
// Each rule's violating and non-violating cases live in the plugin's own unit
// tests (`cherrypick_lint/test/rules/`), which is where behaviour is pinned
// down; README.md lists the rules with wrong/right snippets.
import 'dart:async';

import 'package:cherrypick/cherrypick.dart';

class Logger {
  void log(String message) {}
}

class Api {
  Api(this.logger);

  final Logger logger;
}

class Session implements Disposable {
  Session(this.token);

  final String token;

  @override
  Future<void> dispose() async {}
}

/// A module built by hand — no codegen involved, so this package needs no
/// `build_runner` step.
class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    // The value is constructed inside the closure, so every resolve gets a
    // fresh instance — what avoid_precomputed_value_in_provide checks for.
    bind<Logger>().toProvide(() => Logger());

    // .singleton() after a provider is meaningful: one Api for the scope.
    bind<Api>()
        .toProvide(() => Api(currentScope.resolve<Logger>()))
        .singleton();
  }
}

class SessionModule extends Module {
  SessionModule(this._token);

  final String _token;

  @override
  void builder(Scope currentScope) {
    // A ready-made value belongs in toInstance, without .singleton() —
    // avoid_redundant_singleton_on_instance would flag the redundant call.
    bind<Session>().toInstance(Session(_token));
  }
}

Future<void> main() async {
  final root = CherryPick.openRootScope()..installModules([AppModule()]);
  root.resolve<Api>().logger.log('started');

  final session = root.openSubScope('session')
    ..installModules([SessionModule('token')]);
  session.resolve<Session>();

  // Disposal is awaited: the three avoid_unawaited_* rules exist because
  // dropping these futures leaves Disposable dependencies alive.
  await root.closeSubScope('session');
  await CherryPick.closeRootScope();

  // An intentional fire-and-forget is spelled out with unawaited(), which the
  // rules accept as an explicit choice.
  unawaited(CherryPick.closeRootScope());
}
