import 'package:cherrypick/cherrypick.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' hide State;

import '../../core/di/scope_names.dart';
import '../../core/di/workspace_cubit.dart';
import '../../domain/entity/instrument.dart';
import 'market_tab_bloc.dart';
import 'market_tab_view.dart';

/// The `/market/:symbol` route.
///
/// This is where a URL turns into a DI scope: entering the route asks
/// [WorkspaceCubit] to open `session.market.<symbol>` and resolve the tab's
/// bloc. Until that finishes — the warm-up history is loaded asynchronously —
/// the route shows a spinner.
///
/// Leaving the route does *not* close the scope: tabs stay open until closed
/// explicitly, so navigation switches which one is on screen rather than
/// destroying it.
class MarketTabPage extends StatefulWidget {
  final String symbol;

  const MarketTabPage({super.key, required this.symbol});

  @override
  State<MarketTabPage> createState() => _MarketTabPageState();
}

class _MarketTabPageState extends State<MarketTabPage> {
  @override
  void initState() {
    super.initState();
    _ensureScope();
  }

  @override
  void didUpdateWidget(MarketTabPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ShellRoute reuses this State across /market/A → /market/B.
    if (oldWidget.symbol != widget.symbol) _ensureScope();
  }

  void _ensureScope() =>
      context.read<WorkspaceCubit>().openSymbol(widget.symbol);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkspaceCubit, WorkspaceState>(
      builder: (context, state) {
        final bloc = state.tabs[widget.symbol];
        if (bloc == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Resolved from the tab's own subscope, with runtime params — the
        // manual counterpart to the generated `instrumentTitle` provider.
        final instrument = CherryPick.openScope(
          scopeName: ScopeNames.symbol(widget.symbol),
        ).resolve<Option<Instrument>>(params: widget.symbol);

        // .value, not create: the tab's scope owns this bloc and will close it.
        // A create: constructor here would hand ownership to the widget tree
        // and close it twice.
        return BlocProvider<MarketTabBloc>.value(
          key: ValueKey(widget.symbol),
          value: bloc,
          child: MarketTabView(instrument: instrument),
        );
      },
    );
  }
}
