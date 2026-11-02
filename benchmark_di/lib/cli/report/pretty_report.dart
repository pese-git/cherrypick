import 'report_generator.dart';

/// Generates a human-readable, tab-delimited report for benchmark results.
///
/// Used for terminal and log output; shows each result as a single line with labeled headers.
class PrettyReport extends ReportGenerator {
  /// List of columns to output in the pretty report.
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

  /// Mappings from internal benchmark IDs to display names.
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

  /// Renders the results as a header + tab-separated value table.
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
    final header = headers.join('\t');
    final lines = rows.map((r) {
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
      ].join('\t');
    }).toList();
    return ([header] + lines).join('\n');
  }
}
