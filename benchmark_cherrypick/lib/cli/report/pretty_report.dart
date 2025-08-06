import 'report_generator.dart';

class PrettyReport extends ReportGenerator {
  @override
  final List<String> keys = [
    'benchmark','chainCount','nestingDepth','mean_us','median_us','stddev_us',
    'min_us','max_us','trials','memory_diff_kb','delta_peak_kb','peak_rss_kb'
  ];
  @override
  String render(List<Map<String, dynamic>> rows) {
    final header = keys.join('\t');
    final lines = rows.map((r) => keys.map((k) => (r[k] ?? '').toString()).join('\t')).toList();
    return ([header] + lines).join('\n');
  }
}