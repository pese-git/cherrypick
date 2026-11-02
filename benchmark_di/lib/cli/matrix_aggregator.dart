/// Сводит результаты отдельных процессов в markdown-таблицу «сценарий × DI».
///
/// Отсутствующие измерения помечаются прочерком: молчаливый пропуск строки
/// однажды уже привёл к публикации числа для сценария, который инструмент
/// выполнить не может (yx_scope/chainAsync = 87.2 µs в REPORT.md).
String aggregateMatrix(
  List<Map<String, dynamic>> rows, {
  required String metric,
}) {
  final scenarios = <String>[];
  final dis = <String>[];
  final cells = <String, String>{};

  for (final row in rows) {
    final scenario = row['benchmark'] as String;
    final di = row['di'] as String;
    if (!scenarios.contains(scenario)) scenarios.add(scenario);
    if (!dis.contains(di)) dis.add(di);
    cells['$scenario|$di'] = row[metric]?.toString() ?? '–';
  }

  final buffer = StringBuffer()
    ..writeln('| Scenario | ${dis.join(' | ')} |')
    ..writeln('|---|${dis.map((_) => '---').join('|')}|');
  for (final scenario in scenarios) {
    final values = dis.map((di) => cells['$scenario|$di'] ?? '–').join(' | ');
    buffer.writeln('| $scenario | $values |');
  }
  return buffer.toString();
}
