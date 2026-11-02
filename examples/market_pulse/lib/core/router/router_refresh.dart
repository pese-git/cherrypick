import 'dart:async';

import 'package:cherrypick/cherrypick.dart';
import 'package:flutter/foundation.dart';

/// Turns a bloc's `Stream` into the `Listenable` go_router wants.
///
/// go_router re-evaluates `redirect` when its `refreshListenable` notifies, so
/// this is the wire between "the session ended" and "leave the workspace". The
/// standard bridge, with one addition: it implements [Disposable], so the
/// container cancels the subscription when the root scope closes.
class GoRouterRefreshStream extends ChangeNotifier implements Disposable {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
