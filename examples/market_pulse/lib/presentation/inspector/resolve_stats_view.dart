import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/observability/inspector_cubit.dart';
import '../theme.dart';

/// Per-type resolution counters.
///
/// How to read a row: `12 resolves / 1 inst` is a singleton doing its job;
/// `12 resolves / 12 inst` is a factory — fine when intended, a missing
/// `.singleton()` when not.
class ResolveStatsView extends StatelessWidget {
  const ResolveStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InspectorCubit, InspectorState>(
      builder: (context, state) {
        if (state.resolveStats.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Nothing resolved yet.',
              style: TextStyle(fontSize: 11, color: MarketColors.muted),
            ),
          );
        }

        final rows = state.resolveStats.values.toList()
          ..sort((a, b) => b.resolves.compareTo(a.resolves));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final row in rows.take(12))
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.typeName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    _Badge(
                      label: '${row.resolves} resolves',
                      color: MarketColors.muted,
                    ),
                    const SizedBox(width: 6),
                    _Badge(
                      label: '${row.instances} inst',
                      color: row.instances == 1
                          ? MarketColors.up
                          : MarketColors.accent,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color)),
    );
  }
}
