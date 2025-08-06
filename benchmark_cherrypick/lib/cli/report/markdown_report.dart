import 'report_generator.dart';

class MarkdownReport extends ReportGenerator {
  @override
  final List<String> keys = [
    'benchmark','chainCount','nestingDepth','mean_us','median_us','stddev_us',
    'min_us','max_us','trials','memory_diff_kb','delta_peak_kb','peak_rss_kb'
  ];
  static const nameMap = {
    'Universal_UniversalBenchmark.registerSingleton':'RegisterSingleton',
    'Universal_UniversalBenchmark.chainSingleton':'ChainSingleton',
    'Universal_UniversalBenchmark.chainFactory':'ChainFactory',
    'Universal_UniversalBenchmark.chainAsync':'AsyncChain',
    'Universal_UniversalBenchmark.named':'Named',
    'Universal_UniversalBenchmark.override':'Override',
  };
  @override
  String render(List<Map<String, dynamic>> rows) {
    final headers = [
      'Benchmark', 'Chain Count', 'Depth', 'Mean (us)', 'Median', 'Stddev', 'Min', 'Max', 'N', 'ΔRSS(KB)', 'ΔPeak(KB)', 'PeakRSS(KB)'
    ];
    final header = '| ' + headers.join(' | ') + ' |';
    final divider = '|' + List.filled(headers.length, '---').join('|') + '|';
    final dataRows = rows.map((r) {
      final readableName = nameMap[r['benchmark']] ?? r['benchmark'];
      return [
        readableName,
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
      ].map((cell) => cell.toString().padRight(10)).join(' | ');
    }).map((row) => '| $row |').toList();
    return ([header, divider] + dataRows).join('\n');
  }
}
