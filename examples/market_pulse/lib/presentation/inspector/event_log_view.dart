import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/observability/di_event.dart';
import '../../core/observability/inspector_cubit.dart';
import '../theme.dart';

/// Newest-first feed of everything the container reported.
class EventLogView extends StatelessWidget {
  const EventLogView({super.key});

  static Color _colorOf(DiEventKind kind) => switch (kind) {
    DiEventKind.created => MarketColors.up,
    DiEventKind.disposed => MarketColors.accent,
    DiEventKind.cacheHit => MarketColors.up,
    DiEventKind.cacheMiss => MarketColors.muted,
    DiEventKind.cycle => MarketColors.down,
    DiEventKind.error => MarketColors.down,
    DiEventKind.warning => Colors.amber,
    DiEventKind.scope => MarketColors.accent,
    _ => MarketColors.muted,
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InspectorCubit, InspectorState>(
      builder: (context, state) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Text(
                  'live instances: ${state.liveInstances}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: MarketColors.muted,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: context.read<InspectorCubit>().reset,
                  child: const Text('clear', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: MarketColors.border),
          Expanded(
            child: state.events.isEmpty
                ? const Center(
                    child: Text(
                      'No events recorded.',
                      style: TextStyle(fontSize: 11, color: MarketColors.muted),
                    ),
                  )
                : ListView.builder(
                    itemCount: state.events.length,
                    itemBuilder: (context, index) {
                      final event = state.events[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 3,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 58,
                              child: Text(
                                event.label,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: _colorOf(event.kind),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                event.message,
                                style: const TextStyle(
                                  fontSize: 10,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
