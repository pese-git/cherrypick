# CherryPick in Flutter

## Bootstrapping in `main`

```dart
import 'package:cherrypick/cherrypick.dart';
import 'package:cherrypick_flutter/cherrypick_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:talker_cherrypick_logger/talker_cherrypick_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

void main() {
  final talker = Talker();
  CherryPick.setGlobalObserver(TalkerCherryPickObserver(talker)); // before openRootScope()
  if (kDebugMode) {
    CherryPick.enableGlobalCycleDetection();
    CherryPick.enableGlobalCrossScopeCycleDetection();
  }
  CherryPick.openRootScope().installModules([
    CoreModule(talker: talker), // hand-written module with constructor args
    $AppModule(),               // generated module
  ]);
  runApp(const CherryPickProvider(child: MyApp()));
}
```

The observer is captured when a scope is created, so set it (and the cycle
detection flags) before the first `openRootScope()`.

## `CherryPickProvider`

`CherryPickProvider` is a plain `InheritedWidget` that gives widgets access to
the same global tree; it holds no state of its own and never rebuilds
dependents (`updateShouldNotify` returns `false`).

```dart
final provider = CherryPickProvider.of(context);
final root = provider.openRootScope();                              // == CherryPick.openRootScope()
final cart = provider.openSubScope(scopeName: 'shop.cart');         // == CherryPick.openScope(...)
final repo = cart.resolve<CartRepository>();
```

Resolve in `initState`/`didChangeDependencies` or in a controller, not on every
`build`: a non-singleton binding builds a new instance on every resolve.

## A scope per screen or feature

Open the scope when the feature starts, close it when it ends. Widget
`dispose()` is synchronous, so make the fire-and-forget explicit with
`unawaited` (this also satisfies `cherrypick_lint`):

```dart
import 'dart:async';

class CartPage extends StatefulWidget {
  const CartPage({super.key});
  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  static const _scopeName = 'cart';
  late final CartCubit _cubit;

  @override
  void initState() {
    super.initState();
    final scope = CherryPick.openScope(scopeName: _scopeName)
      ..installModules([CartModule()]);
    _cubit = scope.resolve<CartCubit>();
  }

  @override
  void dispose() {
    unawaited(CherryPick.closeScope(scopeName: _scopeName));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => /* ... */ const SizedBox();
}
```

Notes:

- `openScope` returns the existing scope if the name is already open, so
  installing modules again on re-entry registers the bindings a second time —
  the new ones win, so singletons are silently replaced by fresh instances. Use a
  unique name per instance (for example `'symbol.$id'`), or close the scope
  before reopening it.
- For logic that outlives a widget (session, workspace), own the scope in a
  cubit/bloc/service and `await CherryPick.closeScope(...)` from an async method
  there (see `examples/market_pulse` in the CherryPick repository).
- Objects that hold streams, controllers or sockets should implement
  `Disposable`; the scope that created them calls `dispose()` on close.
- `@injectable()` widgets/controllers call `_inject(this)` and resolve from the
  global tree, so the modules for their `@scope('…')` must already be installed.
