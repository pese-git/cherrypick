import 'dart:async';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';
import 'inject_generator.dart';
import 'module_generator.dart';

/// Универсальный Builder для генераторов Cherrypick с поддержкой кастомного output_dir
/// (указывает директорию для складывания сгенерированных файлов через build.yaml)
class CustomOutputBuilder extends Builder {
  final Generator generator;
  final String extension;
  final String outputDir;
  final Map<String, List<String>> customBuildExtensions;

  CustomOutputBuilder(this.generator, this.extension, this.outputDir, this.customBuildExtensions);

  @override
  Map<String, List<String>> get buildExtensions {
    if (customBuildExtensions.isNotEmpty) {
      return customBuildExtensions;
    }
    // Дефолт: рядом с исходником, как PartBuilder
    return {
      '.dart': [extension],
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    print('[CustomOutputBuilder] build() called for input: \\${inputId.path}');
    final library = await buildStep.resolver.libraryFor(inputId);
    print('[CustomOutputBuilder] resolved library for: \\${inputId.path}');
    final generated = await generator.generate(LibraryReader(library), buildStep);
    print('[CustomOutputBuilder] gen result for input: \\${inputId.path}, isNull: \\${generated == null}, isEmpty: \\${generated?.isEmpty}');
    if (generated == null || generated.isEmpty) return;
    String outputPath;
    if (customBuildExtensions.isNotEmpty) {
      // Кастомная директория/шаблон
      final inputPath = inputId.path;
      final relativeInput = p.relative(inputPath, from: 'lib/');
      final parts = p.split(relativeInput);
      String subdir = '';
      String baseName = parts.last.replaceAll('.dart', '');
      if (parts.length > 1) {
        subdir = parts.first; // Например, 'di'
      }
      outputPath = subdir.isEmpty
        ? p.join('lib', 'generated', '$baseName$extension')
        : p.join('lib', 'generated', subdir, '$baseName$extension');
    } else {
      // Дефолт: рядом с исходником
      outputPath = p.setExtension(inputId.path, extension);
    }
    final outputId = AssetId(inputId.package, outputPath);
    // part of - всегда авто!
    final partOfPath = p.relative(inputId.path, from: p.dirname(outputPath));
    
    // Check if generated code starts with formatting header
    String finalCode;
    if (generated.startsWith('// dart format width=80')) {
      // Find the end of the header (after "// GENERATED CODE - DO NOT MODIFY BY HAND")
      final lines = generated.split('\n');
      int headerEndIndex = -1;
      
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].startsWith('// GENERATED CODE - DO NOT MODIFY BY HAND')) {
          headerEndIndex = i;
          break;
        }
      }
      
      if (headerEndIndex != -1) {
        // Insert part of directive after the header
        final headerLines = lines.sublist(0, headerEndIndex + 1);
        final remainingLines = lines.sublist(headerEndIndex + 1);
        
        final headerPart = headerLines.join('\n');
        final remainingPart = remainingLines.join('\n');
        
        // Preserve trailing newline if original had one
        final hasTrailingNewline = generated.endsWith('\n');
        finalCode = '$headerPart\n\npart of \'$partOfPath\';\n$remainingPart${hasTrailingNewline ? '' : '\n'}';
      } else {
        // Fallback: add part of at the beginning
        finalCode = "part of '$partOfPath';\n\n$generated";
      }
    } else {
      // No header, add part of at the beginning
      finalCode = "part of '$partOfPath';\n\n$generated";
    }
    
    print('[CustomOutputBuilder] writing to output: \\${outputId.path}');
    await buildStep.writeAsString(outputId, finalCode);
    print('[CustomOutputBuilder] successfully written for input: \\${inputId.path}');
  }
}

Builder injectCustomBuilder(BuilderOptions options) {
  final outputDir = options.config['output_dir'] as String? ?? '';
  final buildExtensions = (options.config['build_extensions'] as Map?)?.map((k,v)=>MapEntry(k.toString(), (v as List).map((item)=>item.toString()).toList())) ?? {};
  return CustomOutputBuilder(InjectGenerator(), '.inject.cherrypick.g.dart', outputDir, buildExtensions);
}

Builder moduleCustomBuilder(BuilderOptions options) {
  final outputDir = options.config['output_dir'] as String? ?? '';
  final buildExtensions = (options.config['build_extensions'] as Map?)?.map((k,v)=>MapEntry(k.toString(), (v as List).map((item)=>item.toString()).toList())) ?? {};
  return CustomOutputBuilder(ModuleGenerator(), '.module.cherrypick.g.dart', outputDir, buildExtensions);
}
