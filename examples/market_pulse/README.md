# Market Pulse

A web-only Flutter dashboard built to exercise **every part of the CherryPick
DI surface** in a setting where each feature is load-bearing rather than
decorative — plus a built-in **DI Inspector** that renders what the container is
doing while you use the app.

Stack: `flutter_bloc` for state, `freezed` for immutable states and unions,
`fpdart` for `Option` / `Either` / `TaskEither`, `go_router` for navigation.
There is no backend: prices come from a synthetic feed, so the whole thing runs
from `flutter run -d chrome`.

```
root                          platform: config, instrument universe, both feeds
 └── session                  the signed-in user: UserSession, WatchlistCubit
      └── market              data layer: the currently selected PriceFeed
           ├── BTCUSD         one tab: MarketTabBloc + warm-up history
           └── ETHUSD
```

## Why another example

[`postly`](../postly) shows the canonical layered app: the graph is assembled at
startup and stays put. Market Pulse shows the other half of real life — a graph
that **grows and shrinks while the app runs**. Tabs open and close, the user
signs out, the data source is swapped at runtime, and every one of those is a
scope operation with visible consequences.

## Who owns the bloc

This is the sharpest difference between the two examples, and it is worth
reading the code for.

In `postly`, blocs are created by the widget tree:

```dart
BlocProvider(create: (_) => PostBloc(repository), child: ...)   // widget owns it
```

In Market Pulse they are created by the container and handed to the tree:

```dart
// market_module.dart — inside the session.market.<SYMBOL> scope
bind<MarketTabBloc>().toProvideAsyncWithParams((params) async { ... }).singleton();

// market_tabs_view.dart
BlocProvider<MarketTabBloc>.value(value: bloc, child: const MarketTabView())
```

`.value` is deliberate: it exposes the bloc without taking over its lifetime.
The bridge is one method on the bloc —

```dart
@override
Future<void> dispose() => close();     // CherryPick's Disposable → Bloc.close()
```

— so closing the tab's scope closes the bloc and cancels its price
subscription. Nothing in the widget tree has to remember to do it, and the
subscription cannot outlive the scope that created it.

Both arrangements are legitimate. Widget ownership is right when a bloc's
lifetime *is* the widget's. Container ownership is right when the bloc holds a
resource whose lifetime belongs to a scope — which is exactly the case here.

## A URL is a request for a scope

Every instrument tab has an address:

```
/market/BTCUSD   →   subscope session.market.BTCUSD
```

Paste that into a fresh browser tab and watch the whole chain run: the guard
bounces you to `/login?from=/market/BTCUSD`, signing in opens the `session`
scope, the router resumes the interrupted journey, and `MarketTabPage` opens
`session.market.BTCUSD` and resolves its bloc. The address bar is a control
surface for the dependency graph.

Two rules keep that honest:

**Navigation is the only entry point.** Nothing opens a scope by calling the
cubit directly — the watchlist and the tab strip both call `context.go(...)`,
and the *route* opens the scope. Otherwise the URL and the DI tree drift apart,
which is exactly the bug this example would otherwise be demonstrating by
accident.

**The guard is a match on `Option<UserSession>`**, not an `isLoggedIn` boolean:

```dart
redirect: (context, state) {
  final signedIn = workspace.state.isSignedIn;
  ...
}
```

The same value that decides whether the session scope exists decides whether the
workspace is reachable, so the two cannot disagree.

The router itself is an ordinary binding — `bind<GoRouter>()...singleton()` in
[router_module.dart](lib/core/di/router_module.dart) — resolved with the
workspace cubit it guards on. `refreshListenable` is fed by that cubit's stream
through a small [adapter](lib/core/router/router_refresh.dart) which, like
everything else here, is `Disposable`.

Leaving a route does **not** close its scope: tabs stay open until closed
explicitly, so navigating (and the browser's Back button) switches which one is
on screen. Closing a tab closes the scope, and the router moves to whatever is
left.

Try `/market/NOPE`. A URL can name anything, so the lookup returns
`Option.none()` and the tab renders "Unknown symbol" instead of throwing out of
a route builder.

## Failure as a value

The repository does not throw. It returns `TaskEither<AppFailure, T>` — a
*description* of asynchronous work that may fail, which does nothing until
`.run()`:

```dart
TaskEither<AppFailure, List<double>> loadHistory(String symbol);
```

That leaves two decisions to make explicitly, and both land in interesting
places.

**The DI binding decides what a failure means for the app.** At the composition
root there is no one left to propagate to, so `BootstrapModule` collapses the
`Either` into a value the rest of the graph can simply depend on:

```dart
bind<AppConfig>().withName('remote').toInstance(
  fetchRemoteConfig().getOrElse((_) => AppConfig.offline).run(),
);
```

**A tab folds its failure into state.** The `Either` is carried *through* the
container — the binding's own type is `Either<AppFailure, List<double>>` — and
the bloc folds it into its initial state, so `MarketTabState` is a union with no
nullable history and no "did this load?" flag:

```dart
super(warmUpHistory.match(
  (failure) => MarketTabState.failure(symbol: symbol, failure: failure),
  (prices) => MarketTabState.live(symbol: symbol, prices: prices),
))
```

Click the **DELISTED** instrument to see it: the tab renders the failure, and —
the part that matters here — it opens no feed subscription at all, because there
is nothing to stream.

`Option` does the same job for absence: `WorkspaceState.session` is
`Option<UserSession>` (the login gate is a `match` on it, so "signed out" cannot
be forgotten), and `tryResolve` is wrapped at the call site so its `null` never
travels:

```dart
final optional = Option.fromNullable(scope.tryResolve<AuditTrail>());
```

## Run it

```bash
cd examples/market_pulse
flutter pub get
dart run build_runner build
flutter run -d chrome
```

From the repository root with melos:

```bash
melos bootstrap && melos run codegen && melos run test
```

## Where each DI feature lives

### Bindings

| Feature | Where | What it does |
|---|---|---|
| `toInstance` | [platform_module.dart](lib/core/di/platform_module.dart) | binds values that already exist |
| `toInstance` with a `Future` | [bootstrap_module.dart](lib/core/di/bootstrap_module.dart) | remote config; `toInstanceAsync` is deprecated — `toInstance` takes a `FutureOr` |
| `toProvide` | [bootstrap_module.dart](lib/core/di/bootstrap_module.dart) | repository, built on first use |
| `toProvideAsync` | [bootstrap_module.dart](lib/core/di/bootstrap_module.dart) | the instrument universe |
| `toProvideWithParams` | [market_module.dart](lib/core/di/market_module.dart) | `Instrument` looked up by ticker |
| `toProvideAsyncWithParams` | [market_module.dart](lib/core/di/market_module.dart) | warm-up history as an `Either`, then the `MarketTabBloc` itself |
| `withName` | [app_module.dart](lib/core/di/app_module.dart) | `live` and `replay` implementations of one `PriceFeed` |
| `singleton()` | throughout | one formatter per app, one bloc **per symbol scope** |

### Resolution

| Feature | Where |
|---|---|
| `resolve` | [market_tab_view.dart](lib/presentation/market/market_tab_view.dart) |
| `resolve` with `params` | [market_tab_view.dart](lib/presentation/market/market_tab_view.dart) — `named: 'instrumentTitle'` |
| `resolveAsync` | [main.dart](lib/main.dart), [workspace_cubit.dart](lib/core/di/workspace_cubit.dart) |
| `tryResolve` | [workspace_cubit.dart](lib/core/di/workspace_cubit.dart) — Inspector's LAB tab |

### Scopes and lifetime

| Feature | Where | Visible effect |
|---|---|---|
| `openSubScope` / `openScope('a.b.c')` | [workspace_cubit.dart](lib/core/di/workspace_cubit.dart) | visiting `/market/<SYMBOL>` creates `session.market.<SYMBOL>` |
| `closeScope` | [workspace_cubit.dart](lib/core/di/workspace_cubit.dart) | closing a tab closes its bloc |
| `Disposable` → `close()` | [market_tab_bloc.dart](lib/presentation/market/market_tab_bloc.dart), [watchlist_cubit.dart](lib/presentation/session/watchlist_cubit.dart), [inspector_cubit.dart](lib/core/observability/inspector_cubit.dart) | sign-out closes the user's whole subtree in one call |
| `dropModules` + `installModules` | [workspace_cubit.dart](lib/core/di/workspace_cubit.dart) `switchFeed` | swaps `live` ⇄ `replay` without a restart |

### Diagnostics

| Feature | Where |
|---|---|
| `CherryPickObserver` (all hooks) | [inspector_observer.dart](lib/core/observability/inspector_observer.dart) |
| Observer composition | [composite_observer.dart](lib/core/observability/composite_observer.dart) — Inspector + Talker side by side |
| Bloc transitions in the same log | [main.dart](lib/main.dart) — `Bloc.observer = TalkerBlocObserver(...)` |
| Global / cross-scope cycle detection | [main.dart](lib/main.dart), debug builds only |
| `openSafeScope` + `CircularDependencyException` | [cycle_demo_module.dart](lib/core/di/cycle_demo_module.dart), LAB tab |

### Code generation

| Annotation | Where |
|---|---|
| `@module`, `@provide`, `@instance`, `@singleton`, `@named`, `@params` | [app_module.dart](lib/core/di/app_module.dart) → `$AppModule` |
| `@injectable`, `@inject`, `@named`, `@scope` | [session_header_model.dart](lib/presentation/session/session_header_model.dart) → `_$SessionHeaderModel` |

Both module styles are used deliberately. Generated modules cannot receive
constructor arguments, so anything that must be *passed in* — the awaited
config, the observer created in `main` — is bound by a hand-written module.
Same for injection: `@scope` takes a compile-time constant, so generated field
injection fits fixed scope paths, while a scope per symbol is opened through the
runtime API.

## Three integration details worth knowing

**`Bloc` reserves `onError`.** `BlocBase.onError(Object, StackTrace)` and
`CherryPickObserver.onError(String, Object?, StackTrace?)` are different methods
with the same name, so one class cannot implement both. Hence
[`InspectorObserver`](lib/core/observability/inspector_observer.dart) is a thin
adapter that feeds [`InspectorCubit`](lib/core/observability/inspector_cubit.dart)
instead of the cubit implementing the observer itself.

**Observer callbacks fire during `build`.** Widgets resolve dependencies inside
`build`, and the container reports every resolve synchronously. Emitting state
from that callback would mark another subtree dirty mid-build, so the Inspector
accumulates eagerly and publishes on a microtask.

**`fpdart` exports a `State` monad.** It collides with Flutter's `State`, so any
widget file that needs fpdart types by name imports it as
`import 'package:fpdart/fpdart.dart' hide State;`. Calling methods on an `Option`
you already hold needs no import at all.

**Flutter web hides routes behind a `#` by default.** With the hash strategy
`/market/BTCUSD` never reaches the router — the app would silently fall back to
its initial location, quietly undoing the point of addressing scopes by URL.
`main()` calls `usePathUrlStrategy()` from `flutter_web_plugins`, which is why
the pubspec carries that (web-only) SDK dependency.

There is also a quieter benefit to freezed here. `InspectorState` is compared by
value, so a counter mutated in place would leave the new state `==` to the old
one and the cubit would silently skip the emit. Making `ResolveStats` immutable
removes the possibility — see the note in
[di_event.dart](lib/core/observability/di_event.dart).

## Things worth trying in the app

1. **Open two instruments, then close one.** The Inspector's scope tree shrinks
   and the closed symbol's bloc stops — the subscription died with its scope.
2. **Switch `live` → `replay`.** Tabs are closed first, the market scope's
   modules are dropped and reinstalled, tabs reopen against the new binding.
   Ordering children-first is the point: they hold references to the old feed.
3. **Sign out, then sign back in.** One `closeScope('session')` closes the
   watchlist cubit, every tab bloc and every stream underneath. The new session
   gets a fresh `WatchlistCubit` — visible in the Inspector.
4. **LAB → `resolve<RiskEngine>()`.** A deliberately circular graph reports a
   `CircularDependencyException` naming the chain. Without detection the same
   call recurses until the stack overflows, with nothing pointing at the culprit.
5. **LAB → `probe AuditTrail`.** `tryResolve` answers `Option.none()` where
   `resolve` throws.
6. **Open `DELISTED`.** The repository returns `Left`, the bloc folds it into a
   failure state, and no subscription is opened. The scope tree says so too.
7. **Paste `/market/ETHUSD` into a fresh browser tab.** Guard → sign-in →
   resumed deep link → scope opened. Then use the browser's Back button: both
   tabs stay alive, and only the visible one changes.

## Reading "RESOLVES PER TYPE"

`12 resolves / 1 inst` is a singleton doing its job. `12 resolves / 12 inst` is
a factory — intended for some bindings, a forgotten `.singleton()` for others.
The counter measures object *identity*, so a provider returning a `const` value
also shows one instance, correctly.

## Known gaps in the container

The observer interface declares `onCacheHit` and `onCacheMiss`, but the
container has no call sites for them — they never fire today. The Inspector
implements both hooks anyway (they would light up for free), and derives its
statistics from `onInstanceCreated`, which fires on every successful resolve and
carries the instance, making reuse detectable by identity.

## Tests

```bash
flutter test
```

They assert the behaviour the app demonstrates, not just that widgets build:
closing a scope closes the blocs created inside it and cancels the feed
subscription, a second session does not inherit the first one's watchlist,
switching the feed moves the open streams, the bloc emits as ticks arrive, a
failed history load produces a tab that subscribes to nothing, and the cycle
experiment returns `Left` with its chain.

`routing_test.dart` drives the real router through the app rather than poking it
directly — `redirect` is evaluated by the `Router` widget's parser, so a router
that is never attached to a tree never runs its guard.
