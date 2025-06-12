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

    // Collect and process all @inject fields.
    // Собираем и обрабатываем все поля с @inject.
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

    // ***
    // Добавим определение nullable для типа (например PostRepository? или Future<PostRepository?>)
    bool isNullable = dartType.nullabilitySuffix ==
            NullabilitySuffix.question ||
        (dartType is ParameterizedType &&
            (dartType)
                .typeArguments
                .any((t) => t.nullabilitySuffix == NullabilitySuffix.question));

    return _ParsedInjectField(
      fieldName: field.name,
      coreType: coreTypeName.replaceAll('?', ''), // удаляем "?" на всякий
      isFuture: isFuture,
      isNullable: isNullable,
      scopeName: scopeName,
      namedValue: namedValue,
    );
  }

  /// Generates a line of code that performs the dependency injection for a field.
  /// Handles resolve/resolveAsync, scoping, and named qualifiers.
  ///
  /// Генерирует строку кода, которая внедряет зависимость для поля.
  /// Учитывает resolve/resolveAsync, scoping и named qualifier.
  String _generateInjectionLine(_ParsedInjectField field) {
    // Используем tryResolve для nullable, иначе resolve
    final resolveMethod = field.isFuture
        ? (field.isNullable
            ? 'tryResolveAsync<${field.coreType}>'
            : 'resolveAsync<${field.coreType}>')
        : (field.isNullable
            ? 'tryResolve<${field.coreType}>'
            : 'resolve<${field.coreType}>');

    final openCall = (field.scopeName != null && field.scopeName!.isNotEmpty)
        ? "CherryPick.openScope(scopeName: '${field.scopeName}')"
        : "CherryPick.openRootScope()";

    final params = (field.namedValue != null && field.namedValue!.isNotEmpty)
        ? "(named: '${field.namedValue}')"
        : '()';

    return "    instance.${field.fieldName} = $openCall.$resolveMethod$params;";
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

  /// The base type name (T or Future<T>) / Базовый тип (T или тип из Future<T>).
  final String coreType;

  /// True if the field type is Future<T>; false otherwise
  /// Истина, если поле — Future<T>, иначе — ложь.
  final bool isFuture;

  /// Optional scope annotation argument / Опциональное имя scope.
  final String? scopeName;

  /// Optional named annotation argument / Опциональное имя named.
  final String? namedValue;

  final bool isNullable;

  _ParsedInjectField({
    required this.fieldName,
    required this.coreType,
    required this.isFuture,
    required this.isNullable,
    this.scopeName,
    this.namedValue,
  });
}

/// Builder factory. Used by build_runner.
///
/// Фабрика билдера. Используется build_runner.
Builder injectBuilder(BuilderOptions options) =>
    PartBuilder([InjectGenerator()], '.inject.cherrypick.g.dart');
