import 'package:benchmark_di/cli/matrix_aggregator.dart';
import 'package:test/test.dart';

void main() {
  test('строит таблицу сценарий × DI по указанной метрике', () {
    final table = aggregateMatrix([
      {
        'benchmark': 'Universal_chainLazySingleton',
        'di': 'cherrypick',
        'median_ns': '35200.0',
      },
      {
        'benchmark': 'Universal_chainLazySingleton',
        'di': 'getit',
        'median_ns': '116400.0',
      },
      {
        'benchmark': 'Universal_named',
        'di': 'cherrypick',
        'median_ns': '120.0',
      },
    ], metric: 'median_ns');

    expect(table,
        contains('| Universal_chainLazySingleton | 35200.0 | 116400.0 |'));
    // Отсутствующее измерение помечается прочерком, а не пропускается молча.
    expect(table, contains('| Universal_named | 120.0 | – |'));
  });

  test('пустой вход даёт таблицу без строк, а не падение', () {
    expect(aggregateMatrix([], metric: 'median_ns'), contains('Scenario'));
  });
}
