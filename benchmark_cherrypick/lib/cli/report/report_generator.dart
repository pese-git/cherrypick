abstract class ReportGenerator {
  String render(List<Map<String, dynamic>> results);
  List<String> get keys;
}