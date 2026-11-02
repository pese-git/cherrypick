import 'dart:io';

import 'package:test/test.dart';

void main() {
  final reports = [
    'REPORT_v2.md',
    'REPORT_v2.ru.md',
    'REPORT_BENCHMARK_COMPARISON.md',
  ];

  for (final name in reports) {
    group(name, () {
      test('файл существует', () {
        expect(File(name).existsSync(), isTrue);
      });

      test('объявляет режим компиляции', () {
        final content = File(name).readAsStringSync().toLowerCase();
        expect(content, anyOf(contains('jit'), contains('aot')));
      });

      test('объявляет состояние детектора циклов', () {
        final content = File(name).readAsStringSync().toLowerCase();
        expect(content, contains('cycle detection'));
      });

      test('не подаёт микросекундное среднее как основную метрику', () {
        final content = File(name).readAsStringSync();
        expect(content, isNot(contains('Mean time, µs')),
            reason: 'mean неустойчив к выбросам; основная метрика — '
                'median в наносекундах');
      });
    });
  }

  test('устаревший REPORT.md удалён', () {
    expect(File('REPORT.md').existsSync(), isFalse,
        reason: 'REPORT.md содержал yx_scope/chainAsync = 87.2 µs — сценарий, '
            'который инструмент выполнить не может');
    expect(File('REPORT.ru.md').existsSync(), isFalse);
  });
}
