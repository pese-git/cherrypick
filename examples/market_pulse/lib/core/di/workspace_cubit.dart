import 'package:cherrypick/cherrypick.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entity/user_session.dart';
import '../../presentation/market/market_tab_bloc.dart';
import '../../presentation/session/watchlist_cubit.dart';
import 'cycle_demo_module.dart';
import 'market_module.dart';
import 'optional_dependency.dart';
import 'scope_names.dart';
import 'session_module.dart';

part 'workspace_cubit.freezed.dart';

/// A node of the live scope tree rendered by the Inspector.
@freezed
abstract class ScopeNode with _$ScopeNode {
  const factory ScopeNode({
    required String name,
    required String detail,
    @Default(<ScopeNode>[]) List<ScopeNode> children,
  }) = _ScopeNode;
}

/// What the cycle experiment found.
@freezed
abstract class CycleReport with _$CycleReport {
  const factory CycleReport({
    required String message,
    @Default(<String>[]) List<String> chain,
  }) = _CycleReport;
}

/// Which scopes are open and what lives in them.
@freezed
abstract class WorkspaceState with _$WorkspaceState {
  const factory WorkspaceState({
    /// `none()` until someone signs in. The login gate is literally a match on
    /// this value, so "signed out" cannot be forgotten by a caller.
    @Default(Option<UserSession>.none()) Option<UserSession> session,
    @Default('live') String feedKind,
    @Default(<String, MarketTabBloc>{}) Map<String, MarketTabBloc> tabs,
    @Default(<String>{}) Set<String> opening,
  }) = _WorkspaceState;

  const WorkspaceState._();

  bool get isSignedIn => session.isSome();

  /// True while a tab's subscope is being built — history loads asynchronously.
  bool isOpening(String symbol) => opening.contains(symbol);
}

/// Owns every scope transition in the app.
///
/// The container does not expose its children, and it should not: which scopes
/// exist and when they close is an application decision. Keeping that decision
/// in one cubit is what makes the lifecycle reviewable — and lets the Inspector
/// draw an accurate tree.
///
/// Note what this cubit stores: the *blocs themselves*. They are resolved from
/// their scopes and handed to the widget tree with `BlocProvider.value`, so the
/// tree never closes them.
class WorkspaceCubit extends Cubit<WorkspaceState> implements Disposable {
  WorkspaceCubit() : super(const WorkspaceState());

  Scope get rootScope => CherryPick.openRootScope();
  Scope get sessionScope => CherryPick.openScope(scopeName: ScopeNames.session);
  Scope get marketScope => CherryPick.openScope(scopeName: ScopeNames.market);

  /// The user's watchlist, absent before sign-in.
  Option<WatchlistCubit> get watchlist =>
      state.session.map((_) => sessionScope.resolve<WatchlistCubit>());

  // --- session lifetime ----------------------------------------------------

  /// Opens `session` and `session.market` and installs their modules.
  void signIn(UserSession user) {
    CherryPick.openScope(
      scopeName: ScopeNames.session,
    ).installModules([SessionModule(user)]);

    CherryPick.openScope(
      scopeName: ScopeNames.market,
    ).installModules([MarketDataModule(kind: state.feedKind)]);

    emit(WorkspaceState(session: Option.of(user), feedKind: state.feedKind));
  }

  /// Closes `session`, which recursively disposes the market scope, every open
  /// tab, the watchlist cubit and all live subscriptions — one call.
  Future<void> signOut() async {
    emit(WorkspaceState(feedKind: state.feedKind));

    await CherryPick.closeScope(scopeName: ScopeNames.session);
  }

  // --- market tabs ---------------------------------------------------------

  /// Opens `session.market.<symbol>` and resolves its [MarketTabBloc].
  ///
  /// The bloc is created asynchronously because its warm-up history is, which
  /// is why the whole binding chain uses the `...Async` variants.
  Future<MarketTabBloc> openSymbol(String symbol) async {
    final existing = state.tabs[symbol];
    if (existing != null && !existing.isClosed) {
      watchlist.map((it) => it.activate(symbol));
      return existing;
    }

    emit(state.copyWith(opening: {...state.opening, symbol}));
    watchlist.map((it) => it.open(symbol));

    try {
      final scope = CherryPick.openScope(scopeName: ScopeNames.symbol(symbol))
        ..installModules([SymbolModule(symbol)]);

      final bloc = await scope.resolveAsync<MarketTabBloc>(params: symbol);

      emit(
        state.copyWith(
          tabs: {...state.tabs, symbol: bloc},
          opening: {...state.opening}..remove(symbol),
        ),
      );
      return bloc;
    } catch (_) {
      emit(state.copyWith(opening: {...state.opening}..remove(symbol)));
      rethrow;
    }
  }

  /// Closes the tab's subscope. The container closes the [MarketTabBloc],
  /// which cancels its subscription — no widget has to remember to do it.
  Future<void> closeSymbol(String symbol) async {
    emit(state.copyWith(tabs: {...state.tabs}..remove(symbol)));
    watchlist.map((it) => it.remove(symbol));

    await CherryPick.closeScope(scopeName: ScopeNames.symbol(symbol));
  }

  // --- runtime reconfiguration --------------------------------------------

  /// Swaps the price feed without restarting the app.
  ///
  /// Order matters and is the lesson: children first. Tab scopes hold blocs
  /// subscribed to the *old* feed, so they are closed before the market scope's
  /// modules are dropped and reinstalled, then reopened against the new
  /// binding.
  Future<void> switchFeed(String kind) async {
    if (kind == state.feedKind) return;

    final reopen = state.tabs.keys.toList();
    for (final symbol in reopen) {
      await CherryPick.closeScope(scopeName: ScopeNames.symbol(symbol));
    }

    emit(WorkspaceState(session: state.session, feedKind: kind));

    marketScope
      ..dropModules()
      ..installModules([MarketDataModule(kind: kind)]);

    for (final symbol in reopen) {
      await openSymbol(symbol);
    }
  }

  // --- Inspector experiments ----------------------------------------------

  /// Builds the tree shown in the Inspector.
  ScopeNode buildTree() {
    const rootDetail =
        'AppConfig · InstrumentUniverse · PriceFeed(live/replay)';

    return state.session.match(
      () => const ScopeNode(name: 'root', detail: rootDetail),
      (user) => ScopeNode(
        name: 'root',
        detail: rootDetail,
        children: [
          ScopeNode(
            name: ScopeNames.session,
            detail: 'UserSession(${user.displayName}) · WatchlistCubit',
            children: [
              ScopeNode(
                name: 'market',
                detail: 'SelectedFeed → PriceFeed(named: ${state.feedKind})',
                children: [
                  // Deliberately structural: the tree redraws on scope changes,
                  // not on every tick. Live counters belong next to the chart.
                  for (final entry in state.tabs.entries)
                    ScopeNode(
                      name: entry.key,
                      detail: entry.value.state is MarketTabFailure
                          ? 'MarketTabBloc · no subscription (history failed)'
                          : 'MarketTabBloc · one live feed subscription',
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// `resolve` vs `tryResolve` on a type nobody bound.
  ///
  /// `tryResolve` answers `null`; wrapping it in [Option] is what stops that
  /// `null` from travelling any further into the app.
  (String tryResolveResult, String resolveResult) probeOptionalDependency() {
    final scope = state.isSignedIn ? marketScope : rootScope;

    final optional = Option.fromNullable(scope.tryResolve<AuditTrail>());
    final tryResult = optional.match(
      () => 'tryResolve<AuditTrail>() → Option.none()',
      (it) => 'tryResolve<AuditTrail>() → Option.of($it)',
    );

    String resolveResult;
    try {
      scope.resolve<AuditTrail>();
      resolveResult = 'resolve<AuditTrail>() → unexpectedly resolved';
    } on Object catch (e) {
      resolveResult = 'resolve<AuditTrail>() → threw ${e.runtimeType}';
    }

    return (tryResult, resolveResult);
  }

  /// Resolves a knowingly circular graph in a throwaway scope.
  ///
  /// Returns `Left` when the cycle was caught — the outcome this demo wants.
  /// Uses [CherryPick.openSafeScope], which turns cycle detection on for that
  /// scope. Without detection the same call recurses until the stack gives up,
  /// so that branch is described in the UI and never executed.
  Future<Either<CycleReport, RiskEngine>> runCycleExperiment() async {
    await CherryPick.closeScope(scopeName: ScopeNames.cycleLab);

    final scope = CherryPick.openSafeScope(scopeName: ScopeNames.cycleLab);
    scope.installModules([CycleDemoModule()]);

    try {
      return Either.right(scope.resolve<RiskEngine>());
    } on CircularDependencyException catch (e) {
      return Either.left(
        CycleReport(message: e.message, chain: e.dependencyChain),
      );
    } finally {
      await CherryPick.closeScope(scopeName: ScopeNames.cycleLab);
    }
  }

  /// Chain of types currently being resolved — non-empty only mid-resolution.
  List<String> currentResolutionChain() =>
      CherryPick.getCurrentResolutionChain();

  /// Cross-scope resolution chain tracked by the global detector.
  List<String> globalResolutionChain() => CherryPick.getGlobalResolutionChain();

  @override
  Future<void> dispose() => close();
}
