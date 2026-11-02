import 'dart:convert';

import 'report_generator.dart';

/// Отчёт в машинночитаемом JSON.
///
/// Читается агрегатором матрицы (`bin/matrix.dart`), поэтому формат обязан
/// проходить `jsonDecode` без предобработки. Прежняя реализация печатала
/// `Map.toString()` — ключи без кавычек, распарсить нельзя.
class JsonReport extends ReportGenerator {
  /// No specific keys; outputs all fields in raw map.
  @override
  List<String> get keys => [];

  @override
  String render(List<Map<String, dynamic>> rows) =>
      const JsonEncoder.withIndent('  ').convert(rows);
}
