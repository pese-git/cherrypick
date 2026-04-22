import 'report_generator.dart';

/// Generates a Markdown-formatted report for benchmark results.
///
/// Displays result rows as a visually clear Markdown table including a legend for all metrics.
class MarkdownReport extends ReportGenerator {
  /// List of columns (keys) to show in the Markdown table.
  @override
  final List<String> keys = [
    'benchmark',
    'phase',
    'chainCount',
    'nestingDepth',
    'mean_us',
    'median_us',
    'stddev_us',
    'min_us',
    'max_us',
    'trials',
    'memory_diff_kb',
    'delta_peak_kb',
    'peak_rss_kb'
  ];

  /// Friendly display names for each benchmark type.
  static const nameMap = {
    'Universal_UniversalBenchmark.registerSingleton': 'RegisterSingleton',
    'Universal_UniversalBenchmark.registerLazySingleton': 'RegisterLazySingleton',
    'Universal_UniversalBenchmark.chainSingleton': 'ChainSingleton',
    'Universal_UniversalBenchmark.chainLazySingleton': 'ChainLazySingleton',
    'Universal_UniversalBenchmark.chainFactory': 'ChainFactory',
    'Universal_UniversalBenchmark.chainAsync': 'AsyncChain',
    'Universal_UniversalBenchmark.named': 'Named',
    'Universal_UniversalBenchmark.override': 'Override',
  };

  /// Renders all results as a formatted Markdown table with aligned columns and a legend.
  @override
  String render(List<Map<String, dynamic>> rows) {
    final headers = [
      'Benchmark',
      'Phase',
      'Chain Count',
      'Depth',
      'Mean (us)',
      'Median',
      'Stddev',
      'Min',
      'Max',
      'N',
      'ΔRSS(KB)',
      'ΔPeak(KB)',
      'PeakRSS(KB)'
    ];
    final dataRows = rows.map((r) {
      final readableName = nameMap[r['benchmark']] ?? r['benchmark'];
      return [
        readableName,
        r['phase'],
        r['chainCount'],
        r['nestingDepth'],
        r['mean_us'],
        r['median_us'],
        r['stddev_us'],
        r['min_us'],
        r['max_us'],
        r['trials'],
        r['memory_diff_kb'],
        r['delta_peak_kb'],
        r['peak_rss_kb'],
      ].map((cell) => cell.toString()).toList();
    }).toList();

    // Calculate column width for pretty alignment
    final all = [headers] + dataRows;
    final widths = List.generate(headers.length, (i) {
      return all.map((row) => row[i].length).reduce((a, b) => a > b ? a : b);
    });

    String rowToLine(List<String> row, {String sep = ' | '}) =>
        '| ${List.generate(row.length, (i) => row[i].padRight(widths[i])).join(sep)} |';

    final headerLine = rowToLine(headers);
    final divider = '| ${widths.map((w) => '-' * w).join(' | ')} |';
    final lines = dataRows.map(rowToLine).toList();

    final legend = '''
      > **Legend:**  
      > `Benchmark` – Test name  
      > `Phase` – `firstResolve` or `steadyStateResolve`  
      > `Chain Count` – Number of independent chains  
      > `Depth` – Depth of each chain  
      > `Mean (us)` – Average time per run (microseconds)  
      > `Median` – Median time per run  
      > `Stddev` – Standard deviation  
      > `Min`, `Max` – Min/max run time  
      > `N` – Number of measurements  
      > `ΔRSS(KB)` – Change in process memory (KB)  
      > `ΔPeak(KB)` – Change in peak RSS (KB)  
      > `PeakRSS(KB)` – Max observed RSS memory (KB)  
      ''';

    return '$legend\n\n${([headerLine, divider] + lines).join('\n')}';
  }
}
