import 'report_generator.dart';

class CsvReport extends ReportGenerator {
  @override
  final List<String> keys = [
    'benchmark','chainCount','nestingDepth','mean_us','median_us','stddev_us',
    'min_us','max_us','trials','timings_us','memory_diff_kb','delta_peak_kb','peak_rss_kb'
  ];
  @override
  String render(List<Map<String, dynamic>> rows) {
    final header = keys.join(',');
    final lines = rows.map((r) =>
      keys.map((k) {
        final v = r[k];
        if (v is List) return '"${v.join(';')}"';
        return (v ?? '').toString();
      }).join(',')
    ).toList();
    return ([header] + lines).join('\n');
  }
}