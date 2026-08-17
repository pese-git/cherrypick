import 'package:cherrypick/cherrypick.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entity/user_session.dart';

part 'watchlist_cubit.freezed.dart';

/// Which symbols the user has open, and which tab is active.
@freezed
abstract class WatchlistState with _$WatchlistState {
  const factory WatchlistState({
    @Default(<String>[]) List<String> openSymbols,

    /// `none()` when nothing is open — an absent value the type system knows
    /// about, rather than a `null` every reader has to remember to check.
    @Default(Option<String>.none()) Option<String> activeSymbol,
  }) = _WatchlistState;

  const WatchlistState._();

  bool isOpen(String symbol) => openSymbols.contains(symbol);
}

/// Session-scoped cubit: it belongs to the user, not to the application.
///
/// Bound as a singleton inside `session`, so signing out closes the scope,
/// which closes this cubit — a second user never inherits the first one's tabs.
class WatchlistCubit extends Cubit<WatchlistState> implements Disposable {
  final UserSession session;

  WatchlistCubit(this.session) : super(const WatchlistState());

  void open(String symbol) {
    final symbols = state.isOpen(symbol)
        ? state.openSymbols
        : [...state.openSymbols, symbol];

    emit(WatchlistState(openSymbols: symbols, activeSymbol: Option.of(symbol)));
  }

  /// Named `remove` rather than `close`: `close()` is the cubit's own lifetime
  /// method, and the container is the one that calls it.
  void remove(String symbol) {
    final symbols = [...state.openSymbols]..remove(symbol);
    final active = state.activeSymbol.filter((it) => it != symbol);

    emit(
      WatchlistState(
        openSymbols: symbols,
        // Fall back to the last remaining tab, or to none() if there is none.
        activeSymbol: active.match(
          () => Option.fromNullable(symbols.lastOrNull),
          Option.of,
        ),
      ),
    );
  }

  void activate(String symbol) {
    if (!state.isOpen(symbol)) return;
    emit(
      WatchlistState(
        openSymbols: state.openSymbols,
        activeSymbol: Option.of(symbol),
      ),
    );
  }

  @override
  Future<void> dispose() => close();
}
