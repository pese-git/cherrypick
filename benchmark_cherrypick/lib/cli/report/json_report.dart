import 'report_generator.dart';

class JsonReport extends ReportGenerator {
  @override
  List<String> get keys => [];
  @override
  String render(List<Map<String, dynamic>> rows) {
    return '[\n${rows.map((r) => '  $r').join(',\n')}\n]';
  }
}