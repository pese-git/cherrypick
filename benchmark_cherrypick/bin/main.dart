import 'package:benchmark_cherrypick/cli/benchmark_cli.dart';

Future<void> main(List<String> args) async {
  await BenchmarkCliRunner().run(args);
}