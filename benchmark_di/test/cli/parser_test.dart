import 'package:benchmark_di/cli/parser.dart';
import 'package:test/test.dart';

void main() {
  group('parseBenchmarkCli', () {
    test('пустой список chainCount — ошибка, а не тихий пропуск', () {
      expect(
        () => parseBenchmarkCli(['--chainCount=0']),
        throwsA(isA<BenchmarkCliException>()),
      );
    });

    test('короткий флаг со знаком равенства не молчит', () {
      // args трактует "-c=100" как значение "=100"
      expect(
        () => parseBenchmarkCli(['-c=100']),
        throwsA(isA<BenchmarkCliException>()),
      );
    });

    test('короткий флаг через пробел работает', () {
      final config = parseBenchmarkCli(['-c', '100', '-d', '50']);
      expect(config.chainCounts, [100]);
      expect(config.nestDepths, [50]);
    });

    test('неизвестное имя сценария — ошибка, а не подмена на chainSingleton',
        () {
      expect(
        () => parseBenchmarkCli(['--benchmark=chainSinglton']),
        throwsA(isA<BenchmarkCliException>()),
      );
    });

    test('неизвестный DI — ошибка', () {
      expect(
        () => parseBenchmarkCli(['--di=getit2']),
        throwsA(isA<BenchmarkCliException>()),
      );
    });

    test('корректная конфигурация разбирается', () {
      final config = parseBenchmarkCli([
        '--di=getit',
        '--benchmark=chainLazySingleton',
        '--chainCount=1,10',
        '--nestingDepth=100',
      ]);
      expect(config.di, 'getit');
      expect(config.chainCounts, [1, 10]);
      expect(config.nestDepths, [100]);
      expect(config.benchesToRun, [UniversalBenchmark.chainLazySingleton]);
    });
  });
}
