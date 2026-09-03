import 'dart:convert';
import 'dart:io';

import 'package:benchmark_di/cli/matrix_aggregator.dart';

/// Запускает каждую пару (DI, сценарий) отдельным процессом.
///
/// Изоляция обязательна для памяти: RSS процесса монотонно растёт, поэтому в
/// общем прогоне сценарий наследует пик соседа. В REPORT_v2 у get_it
/// AsyncChain и Named дали побайтово совпадающие 494 928 KB — RSS не менялся,
/// значение просто перешло от предыдущего сценария. Побочно изоляция снимает
/// зависимость от прогрева JIT предыдущими сценариями.
const dis = ['cherrypick', 'getit', 'riverpod', 'kiwi', 'yx_scope'];
const scenarios = [
  'registerSingleton',
  'registerLazySingleton',
  'chainSingleton',
  'chainLazySingleton',
  'chainFactory',
  'chainAsync',
  'named',
  'override',
];

Future<void> main(List<String> args) async {
  final chainCount = _optionOr(args, '--chainCount', '100');
  final nestingDepth = _optionOr(args, '--nestingDepth', '100');
  final repeat = _optionOr(args, '--repeat', '31');
  final warmup = _optionOr(args, '--warmup', '5');
  final phase = _optionOr(args, '--resolvePhase', 'first');
  final metric = _optionOr(args, '--metric', 'median_ns');
  final executable = _optionOr(args, '--exe', 'dart');
  final cycleDetection = args.contains('--cycleDetection');

  final rows = <Map<String, dynamic>>[];
  final skipped = <String>[];

  for (final di in dis) {
    for (final scenario in scenarios) {
      final prefix =
          executable == 'dart' ? ['run', 'bin/main.dart'] : <String>[];
      final result = await Process.run(executable, [
        ...prefix,
        '--di=$di',
        '--benchmark=$scenario',
        '--chainCount=$chainCount',
        '--nestingDepth=$nestingDepth',
        '--repeat=$repeat',
        '--warmup=$warmup',
        '--resolvePhase=$phase',
        '--format=json',
        if (cycleDetection) '--cycleDetection',
      ]);
      if (result.exitCode != 0) {
        skipped.add('$di/$scenario: exit ${result.exitCode} '
            '${(result.stderr as String).trim()}');
        continue;
      }
      final decoded = jsonDecode(result.stdout as String) as List;
      if (decoded.isEmpty) {
        skipped.add('$di/$scenario: ${(result.stderr as String).trim().isEmpty ? //
            'сценарий не поддерживается' : (result.stderr as String).trim()}');
        continue;
      }
      for (final row in decoded.cast<Map<String, dynamic>>()) {
        // 'Universal_UniversalBenchmark.chainSingleton' -> 'chainSingleton'
        row['benchmark'] = (row['benchmark'] as String).split('.').last;
        rows.add(row);
      }
    }
  }

  stdout.writeln('# Матрица: $phase, метрика $metric');
  stdout.writeln();
  stdout.writeln('- chainCount=$chainCount, nestingDepth=$nestingDepth, '
      'repeat=$repeat, warmup=$warmup');
  stdout.writeln(
      '- режим: ${executable == 'dart' ? 'JIT' : 'AOT ($executable)'}');
  stdout.writeln(
      '- cherrypick cycle detection: ${cycleDetection ? 'on' : 'off'}');
  stdout.writeln('- каждая пара (DI, сценарий) — отдельный процесс');
  stdout.writeln();
  stdout.writeln(aggregateMatrix(rows, metric: metric));
  if (skipped.isNotEmpty) {
    stdout.writeln();
    stdout.writeln('## Не измерено');
    stdout.writeln();
    for (final s in skipped) {
      stdout.writeln('- $s');
    }
  }
}

String _optionOr(List<String> args, String name, String fallback) {
  for (final a in args) {
    if (a.startsWith('$name=')) return a.substring(name.length + 1);
  }
  return fallback;
}
