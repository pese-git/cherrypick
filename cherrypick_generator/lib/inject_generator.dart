import 'dart:async';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:cherrypick_annotations/cherrypick_annotations.dart' as ann;

class InjectGenerator extends GeneratorForAnnotation<ann.injectable> {
  const InjectGenerator();

  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@injectable() can only be applied to classes.',
        element: element,
      );
    }

    final classElement = element;
    final className = classElement.name;
    final mixinName = '_\$$className';

    final buffer = StringBuffer()
      ..writeln('mixin $mixinName {')
      ..writeln('  void _inject($className instance) {');

    // Collect and process all @inject fields
    final injectFields =
        classElement.fields.where(_isInjectField).map(_parseInjectField);

    for (final parsedField in injectFields) {
      buffer.writeln(_generateInjectionLine(parsedField));
    }

    buffer
      ..writeln('  }')
      ..writeln('}');

    return buffer.toString();
  }

  // Checks if a field has @inject annotation
  static bool _isInjectField(FieldElement field) {
    return field.metadata.any(
      (m) => m.computeConstantValue()?.type?.getDisplayString() == 'inject',
    );
  }

  // Parsed structure storage
  static _ParsedInjectField _parseInjectField(FieldElement field) {
    String? scopeName;
    String? namedValue;

    for (final meta in field.metadata) {
      final DartObject? obj = meta.computeConstantValue();
      final type = obj?.type?.getDisplayString();
      if (type == 'scope') {
        scopeName = obj?.getField('name')?.toStringValue();
      } else if (type == 'named') {
        namedValue = obj?.getField('value')?.toStringValue();
      }
    }

    final DartType dartType = field.type;
    String coreTypeName;
    bool isFuture;

    if (dartType.isDartAsyncFuture) {
      final ParameterizedType paramType = dartType as ParameterizedType;
      coreTypeName = paramType.typeArguments.first.getDisplayString();
      isFuture = true;
    } else {
      coreTypeName = dartType.getDisplayString();
      isFuture = false;
    }

    return _ParsedInjectField(
      fieldName: field.name,
      coreType: coreTypeName,
      isFuture: isFuture,
      scopeName: scopeName,
      namedValue: namedValue,
    );
  }

  // Generates the injection invocation line for the field
  String _generateInjectionLine(_ParsedInjectField field) {
    final methodName = field.isFuture
        ? 'resolveAsync<${field.coreType}>'
        : 'resolve<${field.coreType}>';
    final openCall = (field.scopeName != null && field.scopeName!.isNotEmpty)
        ? "CherryPick.openScope(scopeName: '${field.scopeName}')"
        : "CherryPick.openRootScope()";
    final params = (field.namedValue != null && field.namedValue!.isNotEmpty)
        ? "(named: '${field.namedValue}')"
        : '()';

    return "    instance.${field.fieldName} = $openCall.$methodName$params;";
  }
}

class _ParsedInjectField {
  final String fieldName;
  final String coreType;
  final bool isFuture;
  final String? scopeName;
  final String? namedValue;

  _ParsedInjectField({
    required this.fieldName,
    required this.coreType,
    required this.isFuture,
    this.scopeName,
    this.namedValue,
  });
}

Builder injectBuilder(BuilderOptions options) =>
    PartBuilder([InjectGenerator()], '.inject.cherrypick.g.dart');
