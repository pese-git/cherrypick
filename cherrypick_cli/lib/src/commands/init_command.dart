import 'package:args/command_runner.dart';
import '../utils/build_yaml_updater.dart';

class InitCommand extends Command {
  @override
  final name = 'init';
  @override
  final description = 'Adds or updates cherrypick_generator sections in build.yaml, preserving other packages.';

  InitCommand() {
    argParser.addOption(
      'output_dir',
      abbr: 'o',
      defaultsTo: 'lib/generated',
      help: 'Directory for generated code.',
    );
    argParser.addOption(
      'build_yaml',
      abbr: 'f',
      defaultsTo: 'build.yaml',
      help: 'Path to build.yaml file.',
    );
  }

  @override
  void run() {
    final outputDir = argResults?['output_dir'] as String? ?? 'lib/generated';
    final buildYaml = argResults?['build_yaml'] as String? ?? 'build.yaml';
    updateCherrypickBuildYaml(
      buildYamlPath: buildYaml,
      outputDir: outputDir,
    );
  }
}
