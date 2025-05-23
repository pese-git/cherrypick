import 'dart:async';
import 'package:analyzer/dart/constant/value.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:cherrypick_annotations/cherrypick_annotations.dart' as ann;

class InjectGenerator extends GeneratorForAnnotation<ann.injectable> {
  const InjectGenerator();

  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@injectable() can only be applied to classes.',
        element: element,
      );
    }

    final classElement = element;
    final className = classElement.name;
    final mixinName = '_\$$className';

    final injectedFields = classElement.fields.where((field) => field.metadata
        .any((m) =>
            m.computeConstantValue()?.type?.getDisplayString() == 'inject'));

    final buffer = StringBuffer();
    buffer.writeln('mixin $mixinName {');
    buffer.writeln('  void _inject($className instance) {');

    for (final field in injectedFields) {
      String? scopeName;
      String? namedValue;

      for (final m in field.metadata) {
        final DartObject? obj = m.computeConstantValue();
        final type = obj?.type?.getDisplayString();
        if (type == 'scope') {
          scopeName = obj?.getField('name')?.toStringValue();
        } else if (type == 'named') {
          namedValue = obj?.getField('value')?.toStringValue();
        }
      }

      final String fieldType = field.type.getDisplayString();

      String accessor = (scopeName != null && scopeName.isNotEmpty)
          ? "CherryPick.openScope(scopeName: '$scopeName').resolve"
          : "CherryPick.openRootScope().resolve";

      String generic = fieldType != 'dynamic' ? '<$fieldType>' : '';
      String params = (namedValue != null && namedValue.isNotEmpty)
          ? "(named: '$namedValue')"
          : '()';

      buffer.writeln("    instance.${field.name} = $accessor$generic$params;");
    }

    buffer.writeln('  }');
    buffer.writeln('}');

    return buffer.toString();
  }
}

Builder injectBuilder(BuilderOptions options) =>
    PartBuilder([InjectGenerator()], '.inject.cherrypick.g.dart');
