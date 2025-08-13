import 'report_generator.dart';

/// Generates a JSON-formatted report for benchmark results.
class JsonReport extends ReportGenerator {
  /// No specific keys; outputs all fields in raw map.
  @override
  List<String> get keys => [];

  /// Renders all result rows as a pretty-printed JSON array.
  @override
  String render(List<Map<String, dynamic>> rows) {
    return '[\n${rows.map((r) => '  $r').join(',\n')}\n]';
  }
}
