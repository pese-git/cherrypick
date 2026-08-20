import 'report_generator.dart';

/// Generates a Markdown-formatted report for benchmark results.
///
/// Displays result rows as a visually clear Markdown table including a legend for all metrics.
class MarkdownReport extends ReportGenerator {
  /// List of columns (keys) to show in the Markdown table.
  @override
  final List<String> keys = [
    'benchmark',
    'di',
    'phase',
    'chainCount',
    'nestingDepth',
    'median_ns',
    'min_ns',
    'p95_ns',
    'mad_ns',
    'ops_per_sample',
    'trials',
    'memory_diff_kb',
    'delta_peak_kb',
    'peak_rss_kb',
    'baseline_rss_kb',
    'rss_over_baseline_kb'
  ];

  /// Friendly display names for each benchmark type.
  static const nameMap = {
    'Universal_UniversalBenchmark.registerSingleton': 'RegisterSingleton',
    'Universal_UniversalBenchmark.registerLazySingleton':
        'RegisterLazySingleton',
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
      'DI',
      'Phase',
      'Chain Count',
      'Depth',
      'Median (ns)',
      'Min (ns)',
      'p95 (ns)',
      'MAD (ns)',
      'Ops',
      'N',
      'ΔRSS(KB)',
      'ΔPeak(KB)',
      'PeakRSS(KB)',
      'RSS-base(KB)'
    ];
    final dataRows = rows.map((r) {
      final readableName = nameMap[r['benchmark']] ?? r['benchmark'];
      return [
        readableName,
        r['di'],
        r['phase'],
        r['chainCount'],
        r['nestingDepth'],
        r['median_ns'],
        r['min_ns'],
        r['p95_ns'],
        r['mad_ns'],
        r['ops_per_sample'],
        r['trials'],
        r['memory_diff_kb'],
        r['delta_peak_kb'],
        r['peak_rss_kb'],
        r['rss_over_baseline_kb'],
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
      > `DI` – Container under test  
      > `Median (ns)` – Median nanoseconds per resolve  
      > `Min (ns)` – Fastest sample; closest to the cost without scheduler noise  
      > `p95 (ns)` – 95th percentile  
      > `MAD (ns)` – Median absolute deviation; outlier-resistant spread  
      > `Ops` – Resolves per sample (1 in the first-resolve phase)  
      > `N` – Number of samples  
      > `ΔRSS(KB)` – Change in process memory (KB)  
      > `ΔPeak(KB)` – Change in peak RSS (KB)  
      > `PeakRSS(KB)` – Max observed RSS memory (KB)  
      > `RSS-base(KB)` – Peak RSS minus the process baseline (~169 MB of VM and JIT code)  
      ''';

    return '$legend\n\n${([headerLine, divider] + lines).join('\n')}';
  }
}
