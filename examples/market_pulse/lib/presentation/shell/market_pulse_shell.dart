import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/workspace_cubit.dart';
import '../../core/router/app_routes.dart';
import '../inspector/inspector_panel.dart';
import '../market/market_tabs_view.dart';
import '../session/session_header_model.dart';
import '../session/watchlist_cubit.dart';
import '../session/watchlist_panel.dart';
import '../theme.dart';

/// Three-pane workspace: watchlist, charts, DI Inspector.
///
/// Built by a `ShellRoute`, so it survives navigation between instruments —
/// the chrome is constructed once while [child] changes with the URL. That
/// matters here beyond looks: [SessionHeaderModel] resolves from the session
/// scope on construction, and rebuilding it on every route change would be
/// pointless work.
///
/// Below 1200px the Inspector moves into an end drawer so the demo stays usable
/// in a narrow browser window.
class MarketPulseShell extends StatefulWidget {
  final Widget child;

  const MarketPulseShell({super.key, required this.child});

  @override
  State<MarketPulseShell> createState() => _MarketPulseShellState();
}

class _MarketPulseShellState extends State<MarketPulseShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _inspectorPinned = true;

  /// Built here rather than in `build`: constructing it runs the generated
  /// `_inject`, which resolves from the session scope.
  late final SessionHeaderModel _header = SessionHeaderModel();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1200;

    // The session-scoped cubit, exposed to the subtree without transferring
    // ownership — the session scope closes it, not this widget.
    return BlocProvider<WatchlistCubit>.value(
      value: _header.watchlist,
      child: Scaffold(
        key: _scaffoldKey,
        endDrawer: wide
            ? null
            : const Drawer(
                width: 420,
                backgroundColor: MarketColors.background,
                child: InspectorPanel(),
              ),
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                header: _header,
                inspectorPinned: wide && _inspectorPinned,
                onToggleInspector: () {
                  if (wide) {
                    setState(() => _inspectorPinned = !_inspectorPinned);
                  } else {
                    _scaffoldKey.currentState?.openEndDrawer();
                  }
                },
              ),
              const Divider(height: 1, color: MarketColors.border),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(width: 280, child: WatchlistPanel()),
                    const VerticalDivider(width: 1, color: MarketColors.border),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const MarketTabStrip(),
                          const Divider(height: 1, color: MarketColors.border),
                          // Whatever the router put here: the empty state or
                          // one instrument's chart.
                          Expanded(child: widget.child),
                        ],
                      ),
                    ),
                    if (wide && _inspectorPinned) ...[
                      const VerticalDivider(
                        width: 1,
                        color: MarketColors.border,
                      ),
                      const SizedBox(width: 420, child: InspectorPanel()),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final SessionHeaderModel header;
  final bool inspectorPinned;
  final VoidCallback onToggleInspector;

  const _TopBar({
    required this.header,
    required this.inspectorPinned,
    required this.onToggleInspector,
  });

  @override
  Widget build(BuildContext context) {
    final workspace = context.read<WorkspaceCubit>();

    return Container(
      height: 56,
      color: MarketColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Web windows get narrow; drop the optional bits before wrapping.
          final compact = constraints.maxWidth < 860;

          return Row(
            children: [
              Text(
                header.appName,
                style: const TextStyle(
                  color: MarketColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  header.session.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: MarketColors.muted),
                ),
              ),
              const Spacer(),
              const _FeedSwitch(),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Talker log console',
                onPressed: () => context.go(AppRoutes.logs),
                icon: const Icon(Icons.receipt_long, size: 20),
              ),
              IconButton(
                tooltip: inspectorPinned
                    ? 'Hide DI Inspector'
                    : 'Show DI Inspector',
                onPressed: onToggleInspector,
                icon: Icon(
                  inspectorPinned ? Icons.science : Icons.science_outlined,
                  size: 20,
                  color: inspectorPinned ? MarketColors.accent : null,
                ),
              ),
              if (compact)
                IconButton(
                  tooltip: 'Sign out — closes the session scope',
                  onPressed: workspace.signOut,
                  icon: const Icon(Icons.logout, size: 18),
                )
              else
                TextButton.icon(
                  onPressed: workspace.signOut,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Sign out'),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Runtime swap of the `PriceFeed` implementation.
///
/// Pressing a segment runs `dropModules()` + `installModules()` on the market
/// scope — no restart, no global mutable flag read by the feed itself.
class _FeedSwitch extends StatelessWidget {
  const _FeedSwitch();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkspaceCubit, WorkspaceState>(
      buildWhen: (previous, current) => previous.feedKind != current.feedKind,
      builder: (context, state) => SegmentedButton<String>(
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        segments: const [
          ButtonSegment(value: 'live', label: Text('live')),
          ButtonSegment(value: 'replay', label: Text('replay')),
        ],
        selected: {state.feedKind},
        onSelectionChanged: (selection) =>
            context.read<WorkspaceCubit>().switchFeed(selection.first),
      ),
    );
  }
}
