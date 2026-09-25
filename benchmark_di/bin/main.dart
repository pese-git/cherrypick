import 'dart:io';

import 'package:benchmark_di/cli/benchmark_cli.dart';
import 'package:benchmark_di/cli/parser.dart';

Future<void> main(List<String> args) async {
  try {
    await BenchmarkCliRunner().run(args);
  } on BenchmarkCliException catch (e) {
    stderr.writeln(e.message);
    exit(64); // EX_USAGE
  }
}
