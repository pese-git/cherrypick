import 'package:benchmark_di/cli/benchmark_cli.dart';

Future<void> main(List<String> args) async {
  await BenchmarkCliRunner().run(args);
}
