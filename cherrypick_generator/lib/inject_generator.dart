//
// Copyright 2021 Sergey Penkovsky (sergey.penkovsky@gmail.com)
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//      http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import 'dart:async';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:cherrypick_annotations/cherrypick_annotations.dart' as ann;
import 'cherrypick_custom_builders.dart' as custom;
import 'src/exceptions.dart';
import 'src/type_parser.dart';
import 'src/annotation_validator.dart';

/// InjectGenerator generates a mixin for a class marked with @injectable()
/// and injects all fields annotated with @inject(), using CherryPick DI.
///
/// For Future<T> fields it calls .resolveAsync<T>(),
/// otherwise .resolve<T>() is used. Scope and named qualifiers are supported.
///
/// ---
///
/// InjectGenerator генерирует миксин для класса с аннотацией @injectable()
/// и внедряет все поля, помеченные @inject(), используя DI-фреймворк CherryPick.
///
/// Для Future<T> полей вызывается .resolveAsync<T>(),
/// для остальных — .resolve<T>(). Поддерживаются scope и named qualifier.
///
class InjectGenerator extends GeneratorForAnnotation<ann.injectable> {
  const InjectGenerator();

  /// The main entry point for code generation.
  ///
  /// Checks class validity, collects injectable fields, and produces injection code.
  ///
  /// Основная точка входа генератора. Проверяет класс, собирает инъектируемые поля и создает код внедрения зависимостей.
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw CherryPickGeneratorException(
        '@injectable() can only be applied to classes',
        element: element,
        category: 'INVALID_TARGET',
        suggestion: 'Apply @injectable() to a class instead of ${element.runtimeType}',
      );
    }

    final classElement = element;
    
    try {
      // Validate class annotations
      AnnotationValidator.validateClassAnnotations(classElement);
      
      return _generateInjectionCode(classElement);
    } catch (e) {
      if (e is CherryPickGeneratorException) {
        rethrow;
      }
      throw CodeGenerationException(
        'Failed to generate injection code: $e',
        element: classElement,
        suggestion: 'Check that all @inject fields have valid types and annotations',
      );
    }
  }
  
  /// Generates the injection code for a class
  String _generateInjectionCode(ClassElement classElement) {
    final className = classElement.name;
    final mixinName = '_\$$className';
    
    // Get the source file name for the part directive
    final sourceFile = classElement.source.shortName;

    // Collect and process all @inject fields.
    final injectFields = classElement.fields
        .where(_isInjectField)
        .map((field) => _parseInjectField(field, classElement))
        .toList();

    final buffer = StringBuffer()
      ..writeln('// dart format width=80')
      ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..writeln()
      ..writeln('// **************************************************************************')
      ..writeln('// InjectGenerator')
      ..writeln('// **************************************************************************')
      ..writeln()
      ..writeln('mixin $mixinName {');

    if (injectFields.isEmpty) {
      // For empty classes, generate a method with empty body
      buffer.writeln('  void _inject($className instance) {}');
    } else {
      buffer.writeln('  void _inject($className instance) {');
      for (final parsedField in injectFields) {
        buffer.writeln(_generateInjectionLine(parsedField));
      }
      buffer.writeln('  }');
    }
    
    buffer.writeln('}');

    return '${buffer.toString()}\n';
  }

  /// Checks if a field has the @inject annotation.
  ///
  /// Проверяет, отмечено ли поле аннотацией @inject.
  static bool _isInjectField(FieldElement field) {
    return field.metadata.any(
      (m) => m.computeConstantValue()?.type?.getDisplayString() == 'inject',
    );
  }

  /// Parses the field for scope/named qualifiers and determines its type.
  /// Returns a [_ParsedInjectField] describing injection information.
  ///
  /// Разбирает поле на наличие модификаторов scope/named и выясняет его тип.
  /// Возвращает [_ParsedInjectField] с информацией о внедрении.
  static _ParsedInjectField _parseInjectField(FieldElement field, ClassElement classElement) {
    try {
      // Validate field annotations
      AnnotationValidator.validateFieldAnnotations(field);
      
      // Parse type using improved type parser
      final parsedType = TypeParser.parseType(field.type, field);
      TypeParser.validateInjectableType(parsedType, field);
      
      // Extract metadata
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

      return _ParsedInjectField(
        fieldName: field.name,
        parsedType: parsedType,
        scopeName: scopeName,
        namedValue: namedValue,
      );
    } catch (e) {
      if (e is CherryPickGeneratorException) {
        rethrow;
      }
      throw DependencyResolutionException(
        'Failed to parse inject field "${field.name}"',
        element: field,
        suggestion: 'Check that the field type is valid and properly imported',
        context: {
          'field_name': field.name,
          'field_type': field.type.getDisplayString(),
          'class_name': classElement.name,
          'error': e.toString(),
        },
      );
    }
  }

  /// Generates a line of code that performs the dependency injection for a field.
  /// Handles resolve/resolveAsync, scoping, and named qualifiers.
  ///
  /// Генерирует строку кода, которая внедряет зависимость для поля.
  /// Учитывает resolve/resolveAsync, scoping и named qualifier.
  String _generateInjectionLine(_ParsedInjectField field) {
    final resolveMethod = '${field.parsedType.resolveMethodName}<${field.parsedType.codeGenType}>';
    final fieldName = field.fieldName;
    
    // Build the scope call
    final openCall = (field.scopeName != null && field.scopeName!.isNotEmpty)
        ? "CherryPick.openScope(scopeName: '${field.scopeName}')"
        : "CherryPick.openRootScope()";
    
    // Build the parameters
    final hasNamedParam = field.namedValue != null && field.namedValue!.isNotEmpty;
    final params = hasNamedParam ? "(named: '${field.namedValue}')" : '()';
    
    // Create the full line
    final fullLine = "    instance.$fieldName = $openCall.$resolveMethod$params;";
    
    // Check if line is too long (dart format width=80, accounting for indentation)
    if (fullLine.length <= 80) {
      return fullLine;
    }
    
    // Format long lines with proper line breaks
    if (hasNamedParam && field.scopeName != null && field.scopeName!.isNotEmpty) {
      // For scoped calls with named parameters, break after openScope
      return "    instance.$fieldName = CherryPick.openScope(\n"
             "      scopeName: '${field.scopeName}',\n"
             "    ).$resolveMethod(named: '${field.namedValue}');";
    } else if (hasNamedParam) {
      // For named parameters without scope, break after the method call
      return "    instance.$fieldName = $openCall.$resolveMethod(\n"
             "      named: '${field.namedValue}',\n"
             "    );";
    } else if (field.scopeName != null && field.scopeName!.isNotEmpty) {
      // For scoped calls without named params, break after openScope with proper parameter formatting
      return "    instance.$fieldName = CherryPick.openScope(\n"
             "      scopeName: '${field.scopeName}',\n"
             "    ).$resolveMethod();";
    } else {
      // For simple long calls, break after openRootScope
      return "    instance.$fieldName = $openCall\n"
             "        .$resolveMethod();";
    }
  }
}

/// Data structure representing all information required to generate
/// injection code for a field.
///
/// Структура данных, содержащая всю информацию,
/// необходимую для генерации кода внедрения для поля.
class _ParsedInjectField {
  /// The name of the field / Имя поля.
  final String fieldName;

  /// Parsed type information / Информация о типе поля.
  final ParsedType parsedType;

  /// Optional scope annotation argument / Опциональное имя scope.
  final String? scopeName;

  /// Optional named annotation argument / Опциональное имя named.
  final String? namedValue;

  _ParsedInjectField({
    required this.fieldName,
    required this.parsedType,
    this.scopeName,
    this.namedValue,
  });
  
  @override
  String toString() {
    return '_ParsedInjectField(fieldName: $fieldName, parsedType: $parsedType, '
           'scopeName: $scopeName, namedValue: $namedValue)';
  }
}

/// Builder factory. Used by build_runner.
///
/// Фабрика билдера. Используется build_runner.
Builder injectBuilder(BuilderOptions options) =>
    custom.injectCustomBuilder(options);
