import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:json2yaml/json2yaml.dart';

void updateCherrypickBuildYaml({
  String buildYamlPath = 'build.yaml',
  String outputDir = 'lib/generated',
}) {
  final file = File(buildYamlPath);
  final exists = file.existsSync();
  Map config = {};
  if (exists) {
    final content = file.readAsStringSync();
    final loaded = loadYaml(content);
    config = _deepYamlToMap(loaded);
  }

  // Гарантируем вложенность
  config['targets'] ??= {};
  final targets = config['targets'] as Map;
  targets['\$default'] ??= {};
  final def = targets['\$default'] as Map;
  def['builders'] ??= {};
  final builders = def['builders'] as Map;

  builders['cherrypick_generator|inject_generator'] = {
    'options': {
      'build_extensions': {
        '^lib/{{}}.dart': ['${outputDir}/{{}}.inject.cherrypick.g.dart']
      },
      'output_dir': outputDir
    },
    'generate_for': ['lib/**.dart']
  };

  builders['cherrypick_generator|module_generator'] = {
    'options': {
      'build_extensions': {
        '^lib/di/{{}}.dart': ['${outputDir}/di/{{}}.module.cherrypick.g.dart']
      },
      'output_dir': outputDir
    },
    'generate_for': ['lib/**.dart']
  };

  final yamlString = json2yaml(_stringifyKeys(config), yamlStyle: YamlStyle.pubspecYaml);
  file.writeAsStringSync(yamlString);
  print('✅ build.yaml has been successfully updated and formatted (cherrypick sections added/updated).');
}

dynamic _stringifyKeys(dynamic node) {
  if (node is Map) {
    return Map.fromEntries(
      node.entries.map(
        (e) => MapEntry(e.key.toString(), _stringifyKeys(e.value)),
      ),
    );
  } else if (node is List) {
    return node.map(_stringifyKeys).toList();
  } else {
    return node;
  }
}


/// Рекурсивно преобразует YamlMap/YamlList в обычные Map/List
dynamic _deepYamlToMap(dynamic node) {
  if (node is YamlMap) {
    return Map.fromEntries(node.entries.map((e) => MapEntry(e.key, _deepYamlToMap(e.value))));
  } else if (node is YamlList) {
    return node.map(_deepYamlToMap).toList();
  } else {
    return node;
  }
}

