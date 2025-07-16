import 'package:args/command_runner.dart';
import 'package:cherrypick_cli/src/commands/init_command.dart';

void main(List<String> args) {
  final runner = CommandRunner('cherrypick_cli', 'CherryPick CLI')
    ..addCommand(InitCommand());
  runner.run(args);
}
