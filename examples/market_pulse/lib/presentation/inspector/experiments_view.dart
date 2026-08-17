import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// fpdart exports its own `State` monad, which collides with Flutter's State.
import 'package:fpdart/fpdart.dart' hide State;

import '../../core/di/cycle_demo_module.dart';
import '../../core/di/workspace_cubit.dart';
import '../theme.dart';

/// Two experiments that are awkward to explain in prose and obvious to run.
class ExperimentsView extends StatefulWidget {
  const ExperimentsView({super.key});

  @override
  State<ExperimentsView> createState() => _ExperimentsViewState();
}

class _ExperimentsViewState extends State<ExperimentsView> {
  /// `Left` means the cycle was caught — the outcome this experiment wants.
  Either<CycleReport, RiskEngine>? _cycleResult;
  (String, String)? _optionalResult;

  Future<void> _runCycle() async {
    final result = await context.read<WorkspaceCubit>().runCycleExperiment();
    if (mounted) setState(() => _cycleResult = result);
  }

  void _runOptional() {
    final result = context.read<WorkspaceCubit>().probeOptionalDependency();
    setState(() => _optionalResult = result);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _Card(
          title: 'Circular dependency',
          body:
              'RiskEngine needs PortfolioService, which needs RiskEngine. '
              'Resolved in a throwaway scope opened with openSafeScope(), so '
              'cycle detection is on. Without it the same call recurses until '
              'the stack overflows — with no clue which types are at fault.',
          action: 'resolve<RiskEngine>()',
          onPressed: _runCycle,
          result: _cycleResult?.match(
            (report) =>
                'Left — CircularDependencyException\n'
                '${report.message}\n\n'
                'chain: ${report.chain.join(' → ')}',
            (_) => 'Right — resolved without complaint, cycle went unnoticed.',
          ),
          resultColor: _cycleResult?.isLeft() == true
              ? MarketColors.down
              : null,
        ),
        const SizedBox(height: 12),
        _Card(
          title: 'resolve vs tryResolve',
          body:
              'AuditTrail is deliberately never bound. Optional integrations '
              'should be looked up with tryResolve, which answers null instead '
              'of throwing.',
          action: 'probe AuditTrail',
          onPressed: _runOptional,
          result: _optionalResult == null
              ? null
              : '${_optionalResult!.$1}\n${_optionalResult!.$2}',
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String body;
  final String action;
  final VoidCallback onPressed;
  final String? result;
  final Color? resultColor;

  const _Card({
    required this.title,
    required this.body,
    required this.action,
    required this.onPressed,
    this.result,
    this.resultColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MarketColors.surface,
        border: Border.all(color: MarketColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 10,
              height: 1.6,
              color: MarketColors.muted,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: onPressed,
              child: Text(action, style: const TextStyle(fontSize: 11)),
            ),
          ),
          if (result != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: MarketColors.background,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                result!,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.6,
                  color: resultColor ?? MarketColors.up,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
