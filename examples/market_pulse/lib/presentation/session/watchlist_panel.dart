import 'package:cherrypick_flutter/cherrypick_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/instrument_universe.dart';
import '../../core/di/workspace_cubit.dart';
import '../../core/router/app_routes.dart';
import '../theme.dart';

/// The instrument universe, resolved straight from the root scope.
///
/// Uses [CherryPickProvider] instead of a constructor parameter on purpose:
/// that is the widget-tree entry point `cherrypick_flutter` provides.
class WatchlistPanel extends StatelessWidget {
  const WatchlistPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final universe = CherryPickProvider.of(
      context,
    ).openRootScope().resolve<InstrumentUniverse>();

    return Container(
      color: MarketColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'INSTRUMENTS',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.2,
                color: MarketColors.muted,
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<WorkspaceCubit, WorkspaceState>(
              builder: (context, state) => ListView.builder(
                itemCount: universe.items.length,
                itemBuilder: (context, index) {
                  final instrument = universe.items[index];
                  final isOpen = state.tabs.containsKey(instrument.symbol);
                  final isOpening = state.isOpening(instrument.symbol);

                  return ListTile(
                    dense: true,
                    selected: isOpen,
                    selectedTileColor: MarketColors.surfaceAlt,
                    title: Text(
                      instrument.symbol,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isOpen ? MarketColors.accent : null,
                      ),
                    ),
                    subtitle: Text(
                      instrument.title,
                      style: const TextStyle(
                        fontSize: 11,
                        color: MarketColors.muted,
                      ),
                    ),
                    trailing: isOpening
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isOpen ? Icons.check_circle : Icons.add,
                            size: 16,
                            color: MarketColors.muted,
                          ),
                    // Navigate, do not open the scope directly: the URL is the
                    // single entry point, so the address bar and the DI tree
                    // can never disagree about what is open.
                    onTap: () =>
                        context.go(AppRoutes.symbol(instrument.symbol)),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1, color: MarketColors.border),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Opening an instrument opens the subscope\n'
              'session.market.<SYMBOL>',
              style: TextStyle(
                fontSize: 10,
                height: 1.5,
                color: MarketColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
