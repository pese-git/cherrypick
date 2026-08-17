import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/workspace_cubit.dart';
import '../../core/router/app_routes.dart';
import '../session/watchlist_cubit.dart';
import '../theme.dart';

/// Tab strip, rendered by the shell above whatever route is active.
///
/// Tab order and the active tab live in the session-scoped [WatchlistCubit],
/// but *navigation* is the router's job: tapping a tab changes the URL, and the
/// URL is what brings the corresponding scope into existence.
class MarketTabStrip extends StatelessWidget {
  const MarketTabStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WatchlistCubit, WatchlistState>(
      builder: (context, watchlist) {
        if (watchlist.openSymbols.isEmpty) return const SizedBox.shrink();

        final active = watchlist.activeSymbol.toNullable();

        return Container(
          height: 44,
          color: MarketColors.surface,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: watchlist.openSymbols.length,
            itemBuilder: (context, index) {
              final symbol = watchlist.openSymbols[index];

              return _Tab(symbol: symbol, isActive: symbol == active);
            },
          ),
        );
      },
    );
  }
}

class _Tab extends StatelessWidget {
  final String symbol;
  final bool isActive;

  const _Tab({required this.symbol, required this.isActive});

  Future<void> _close(BuildContext context) async {
    final workspace = context.read<WorkspaceCubit>();
    final router = GoRouter.of(context);

    await workspace.closeSymbol(symbol);
    if (!context.mounted) return;

    // Where to go once the scope is gone: the tab that became active, or the
    // empty workspace.
    final next = workspace.state.tabs.keys.lastOrNull;
    router.go(next == null ? AppRoutes.market : AppRoutes.symbol(next));
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(AppRoutes.symbol(symbol)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isActive ? MarketColors.background : null,
          border: Border(
            bottom: BorderSide(
              width: 2,
              color: isActive ? MarketColors.accent : Colors.transparent,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              symbol,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? MarketColors.accent : MarketColors.muted,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _close(context),
              child: const Icon(
                Icons.close,
                size: 14,
                color: MarketColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The `/market` route: nothing selected yet.
class MarketTabsView extends StatelessWidget {
  const MarketTabsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart, size: 40, color: MarketColors.border),
            SizedBox(height: 12),
            Text(
              'Pick an instrument on the left.\n'
              'Each open tab is its own DI subscope, addressed by URL — watch '
              'the tree in the Inspector grow and shrink.',
              textAlign: TextAlign.center,
              style: TextStyle(color: MarketColors.muted, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
