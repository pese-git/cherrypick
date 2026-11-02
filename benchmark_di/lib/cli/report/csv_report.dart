import 'report_generator.dart';

/// Generates a CSV-formatted report for benchmark results.
class CsvReport extends ReportGenerator {
  /// List of all keys/columns to include in the CSV output.
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
    'timings_ns',
    'memory_diff_kb',
    'delta_peak_kb',
    'peak_rss_kb',
    'baseline_rss_kb',
    'rss_over_baseline_kb'
  ];

  /// Renders rows as a CSV table string.
  @override
  String render(List<Map<String, dynamic>> rows) {
    final header = keys.join(',');
    final lines = rows
        .map((r) => keys.map((k) {
              final v = r[k];
              if (v is List) return '"${v.join(';')}"';
              return (v ?? '').toString();
            }).join(','))
        .toList();
    return ([header] + lines).join('\n');
  }
}
