/// Abstract base for generating benchmark result reports in different formats.
///
/// Subclasses implement [render] to output results, and [keys] to define columns (if any).
abstract class ReportGenerator {
  /// Renders the given [results] as a formatted string (table, markdown, csv, etc).
  String render(List<Map<String, dynamic>> results);
  /// List of output columns/keys included in the export (or [] for auto/all).
  List<String> get keys;
}