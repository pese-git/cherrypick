import 'dart:convert';

import 'package:benchmark_di/cli/report/json_report.dart';
import 'package:test/test.dart';

void main() {
  test('вывод JsonReport парсится jsonDecode', () {
    final rendered = JsonReport().render([
      {
        'benchmark': 'Universal_chainLazySingleton',
        'phase': 'firstResolve',
        'chainCount': 100,
        'nestingDepth': 100,
        'median_ns': '35200.00',
        'trials': 5,
        'timings_ns': ['33000.00', '35200.00'],
        'peak_rss_kb': 294000,
      }
    ]);

    final decoded = jsonDecode(rendered);
    expect(decoded, isA<List>());
    expect(decoded[0]['benchmark'], 'Universal_chainLazySingleton');
    expect(decoded[0]['chainCount'], 100);
    expect(decoded[0]['timings_ns'], hasLength(2));
  });

  test('пустой список результатов даёт валидный пустой JSON', () {
    expect(jsonDecode(JsonReport().render([])), isEmpty);
  });
}
