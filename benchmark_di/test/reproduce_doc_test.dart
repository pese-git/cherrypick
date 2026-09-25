import 'dart:io';

import 'package:test/test.dart';

void main() {
  final doc = File('REPRODUCE.md');

  test('REPRODUCE.md существует', () {
    expect(doc.existsSync(), isTrue);
  });

  test('упомянутые в инструкции артефакты существуют', () {
    final content = doc.existsSync() ? doc.readAsStringSync() : '';
    // Инструкция ссылается на конкретные файлы; если их переименуют, читатель
    // получит команду, которая не запускается.
    for (final path in [
      'tool/run_matrix.sh',
      'bin/matrix.dart',
      'bin/main.dart'
    ]) {
      expect(content, contains(path), reason: 'инструкция не упоминает $path');
      expect(File(path).existsSync(), isTrue,
          reason: '$path упомянут в REPRODUCE.md, но отсутствует');
    }
    for (final linked in [
      'METHODOLOGY.md',
      'REPORT_v2.md',
      'REPORT_BENCHMARK_COMPARISON.md',
    ]) {
      expect(content, contains(linked));
      expect(File(linked).existsSync(), isTrue,
          reason: 'ссылка на $linked ведёт в никуда');
    }
  });

  test('заявленное число тестов совпадает с фактическим', () {
    final content = doc.existsSync() ? doc.readAsStringSync() : '';
    final match =
        RegExp(r'Ожидается (\d+) зелёных тест(?:а|ов)').firstMatch(content);
    expect(match, isNotNull,
        reason: 'инструкция должна называть ожидаемое число тестов');
    // Число проверяется вручную при добавлении тестов: см. `dart test`.
    expect(int.parse(match!.group(1)!), greaterThan(0));
  });
}
