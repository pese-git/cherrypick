import 'dart:async';
import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:cherrypick_annotations/cherrypick_annotations.dart' as ann;

class InjectGenerator extends GeneratorForAnnotation<ann.injectable> {
  const InjectGenerator();

  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    // Only classes are supported for @module() annotation
    // Обрабатываются только классы (другие элементы — ошибка)
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

    // Генерируем инициализацию для каждого поля с аннотацией @inject()
    final buffer = StringBuffer();
    buffer.writeln('mixin $mixinName {');
    buffer.writeln('  void _inject($className instance) {');

    for (final field in injectedFields) {
      // Получаем имя типа
      final fieldType = field.type.getDisplayString();
      // Ищем аннотацию @named
      final namedAnnotation = field.metadata.firstWhereOrNull(
        (m) => m.computeConstantValue()?.type?.getDisplayString() == 'named',
      );
      String namedParam = '';
      if (namedAnnotation != null) {
        final namedValue = namedAnnotation
            .computeConstantValue()
            ?.getField('value')
            ?.toStringValue();
        if (namedValue != null) {
          namedParam = "(named: '$namedValue')";
        }
      }
      buffer.writeln(
          "    instance.${field.name} = CherryPick.openRootScope().resolve<$fieldType>$namedParam;");
    }

    buffer.writeln('  }');
    buffer.writeln('}');

    return buffer.toString();
  }
}

Builder injectBuilder(BuilderOptions options) =>
    PartBuilder([InjectGenerator()], '.inject.cherrypick.g.dart');
