import 'package:cherrypick_flutter/cherrypick_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../core/di/scope_names.dart';
import '../../core/format/quote_formatter.dart';
import '../../domain/entity/instrument.dart';
import '../theme.dart';
import 'market_tab_bloc.dart';
import 'sparkline.dart';

/// One instrument tab, driven entirely by its scope-owned [MarketTabBloc].
class MarketTabView extends StatelessWidget {
  /// Absent when the URL named a ticker that is not in the universe.
  final Option<Instrument> instrument;

  const MarketTabView({super.key, required this.instrument});

  @override
  Widget build(BuildContext context) {
    final rootScope = CherryPickProvider.of(context).openRootScope();

    // Root-scope singleton: resolved on every repaint, constructed once. The
    // Inspector's resolves/instances counters show exactly that.
    final formatter = rootScope.resolve<QuoteFormatter>();

    return BlocBuilder<MarketTabBloc, MarketTabState>(
      builder: (context, state) {
        // A generated provider that takes runtime params.
        final title = rootScope.resolve<String>(
          named: 'instrumentTitle',
          params: state.symbol,
        );

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(state: state, title: title, formatter: formatter),
              const SizedBox(height: 20),
              // Exhaustive by construction: adding a third state to the union
              // turns this switch into a compile error rather than a blank tab.
              Expanded(
                child: switch (state) {
                  MarketTabLive(:final prices) => Sparkline(
                    values: prices,
                    color: prices.length < 2 || prices.last >= prices.first
                        ? MarketColors.up
                        : MarketColors.down,
                  ),
                  MarketTabFailure(:final failure) => _FailureBody(
                    message: failure.message,
                  ),
                },
              ),
              const SizedBox(height: 16),
              _ScopeFootnote(state: state, instrument: instrument),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final MarketTabState state;
  final String title;
  final QuoteFormatter formatter;

  const _Header({
    required this.state,
    required this.title,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final color = state.delta >= 0 ? MarketColors.up : MarketColors.down;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.symbol,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: MarketColors.muted),
            ),
          ],
        ),
        const Spacer(),
        if (state is MarketTabLive)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatter.price(state.last),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                formatter.change(state.delta),
                style: TextStyle(fontSize: 12, color: color),
              ),
            ],
          ),
      ],
    );
  }
}

class _FailureBody extends StatelessWidget {
  final String message;

  const _FailureBody({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 36, color: MarketColors.down),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: MarketColors.down),
          ),
          const SizedBox(height: 8),
          const Text(
            'The repository returned a Left, and the bloc folded it into its\n'
            'initial state. No exception crossed the DI boundary — and no\n'
            'feed subscription was opened for a tab that has nothing to show.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.6,
              color: MarketColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Makes the tab's DI story explicit next to the chart.
class _ScopeFootnote extends StatelessWidget {
  final MarketTabState state;
  final Option<Instrument> instrument;

  const _ScopeFootnote({required this.state, required this.instrument});

  @override
  Widget build(BuildContext context) {
    // Resolved from the tab's own scope with runtime params, and absent when
    // the URL named something that does not exist.
    final specifics = instrument.match(
      () => 'no such instrument — this tab came from a URL',
      (it) =>
          'base ${it.basePrice} · volatility '
          '${(it.volatility * 100).toStringAsFixed(2)}%',
    );

    final detail = switch (state) {
      MarketTabLive(:final tickCount) =>
        '$tickCount ticks received · MarketTabBloc is a singleton inside this '
            'subscope · closing the tab closes the bloc and cancels its '
            'subscription',
      MarketTabFailure() =>
        'History unavailable · the bloc exists but subscribed to nothing · '
            'closing the tab still closes it',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MarketColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MarketColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'scope: ${ScopeNames.symbol(state.symbol)}  ·  url: '
            '/market/${state.symbol}',
            style: const TextStyle(fontSize: 11, color: MarketColors.accent),
          ),
          const SizedBox(height: 6),
          Text(
            '$detail · $specifics',
            style: const TextStyle(
              fontSize: 11,
              height: 1.5,
              color: MarketColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
