import 'package:cherrypick_flutter/cherrypick_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/observability/inspector_cubit.dart';
import '../theme.dart';
import 'event_log_view.dart';
import 'experiments_view.dart';
import 'resolve_stats_view.dart';
import 'scope_tree_view.dart';

/// The DI Inspector: the container's own behaviour, rendered.
///
/// Nothing here is special-cased by the framework — it is all built from
/// `CherryPickObserver` callbacks plus the scope bookkeeping in
/// `WorkspaceCubit`. Any app can grow the same panel.
class InspectorPanel extends StatelessWidget {
  const InspectorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final inspector = CherryPickProvider.of(
      context,
    ).openRootScope().resolve<InspectorCubit>();

    return BlocProvider<InspectorCubit>.value(
      value: inspector,
      child: DefaultTabController(
        length: 3,
        child: Container(
          color: MarketColors.surface,
          child: const Column(
            children: [
              SizedBox(
                height: 40,
                child: TabBar(
                  labelStyle: TextStyle(fontSize: 11),
                  indicatorColor: MarketColors.accent,
                  labelColor: MarketColors.accent,
                  unselectedLabelColor: MarketColors.muted,
                  tabs: [
                    Tab(text: 'SCOPES'),
                    Tab(text: 'EVENTS'),
                    Tab(text: 'LAB'),
                  ],
                ),
              ),
              Divider(height: 1, color: MarketColors.border),
              Expanded(
                child: TabBarView(
                  children: [_ScopesTab(), EventLogView(), ExperimentsView()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScopesTab extends StatelessWidget {
  const _ScopesTab();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Expanded(child: ScopeTreeView()),
        Divider(height: 1, color: MarketColors.border),
        Padding(
          padding: EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'RESOLVES PER TYPE',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.1,
                color: MarketColors.muted,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: SingleChildScrollView(child: ResolveStatsView()),
        ),
      ],
    );
  }
}
