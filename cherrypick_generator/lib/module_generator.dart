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

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:cherrypick_annotations/cherrypick_annotations.dart' as ann;

/// Генератор DI-модулей для фреймворка cherrypick.
/// Генерирует расширение для класса с аннотацией @module,
/// автоматически создавая биндинги для зависимостей, определённых в модуле.
///
/// Пример:
/// ```dart
/// @module()
/// abstract class AppModule extends Module {
///   @singleton()
///   Dio dio() => Dio();
/// }
/// ```
///
/// Сгенерирует код:
/// ```dart
/// final class $AppModule extends AppModule {
///   @override
///   void builder(Scope currentScope) {
///     bind<Dio>().toProvide(() => dio()).singleton();
///   }
/// }
/// ```
class ModuleGenerator extends GeneratorForAnnotation<ann.module> {
  /// Основной метод генерации кода для аннотированного класса-модуля.
  /// [element] - класс с аннотацией @module.
  /// [annotation], [buildStep] - служебные параметры build_runner.
  /// Возвращает сгенерированный Dart-код класса-расширения.
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    // Убеждаемся, что аннотирован только класс (не функция, не переменная).
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@module() может быть применён только к классам.',
        element: element,
      );
    }

    final classElement = element;
    final className = classElement.displayName;

    // Имя сгенерированного класса (например: $AppModule)
    final generatedClassName = r'$' + className;

    final buffer = StringBuffer();

    // Объявление генерируемого класса как final, который наследуется от исходного модуля
    buffer.writeln('final class $generatedClassName extends $className {');
    buffer.writeln('  @override');
    buffer.writeln('  void builder(Scope currentScope) {');

    // Обрабатываем все НЕ-абстрактные методы модуля
    for (final method in classElement.methods.where((m) => !m.isAbstract)) {
      // Проверка на наличие аннотации @singleton() у метода
      final hasSingleton = method.metadata.any(
        (m) =>
            m
                .computeConstantValue()
                ?.type
                ?.getDisplayString()
                .toLowerCase()
                .contains('singleton') ??
            false,
      );

      // Проверяем, есть ли у метода @named('...')
      ElementAnnotation? namedMeta;
      try {
        namedMeta = method.metadata.firstWhere(
          (m) =>
              m
                  .computeConstantValue()
                  ?.type
                  ?.getDisplayString()
                  .toLowerCase()
                  .contains('named') ??
              false,
        );
      } catch (_) {
        namedMeta = null;
      }

      // Извлекаем значение name из @named('value')
      String? nameArg;
      if (namedMeta != null) {
        final cv = namedMeta.computeConstantValue();
        if (cv != null) {
          nameArg = cv.getField('value')?.toStringValue();
        }
      }

      // Формируем список аргументов для вызова метода.
      // Каждый параметр может быть с аннотацией @named, либо без.
      final args = method.parameters.map((p) {
        // Проверяем наличие @named('value') на параметре
        ElementAnnotation? paramNamed;
        try {
          paramNamed = p.metadata.firstWhere(
            (m) =>
                m
                    .computeConstantValue()
                    ?.type
                    ?.getDisplayString()
                    .toLowerCase()
                    .contains('named') ??
                false,
          );
        } catch (_) {
          paramNamed = null;
        }

        String argExpr;
        if (paramNamed != null) {
          final cv = paramNamed.computeConstantValue();
          final namedValue = cv?.getField('value')?.toStringValue();
          // Если указано имя для параметра (@named), пробрасываем его в resolve
          if (namedValue != null) {
            argExpr =
                "currentScope.resolve<${p.type.getDisplayString()}>(named: '$namedValue')";
          } else {
            // fallback — скобки все равно нужны
            argExpr = "currentScope.resolve<${p.type.getDisplayString()}>()";
          }
        } else {
          // Если параметр не @named - просто resolve по типу
          argExpr = "currentScope.resolve<${p.type.getDisplayString()}>()";
        }
        return argExpr;
      }).join(', ');

      final returnType = method.returnType.getDisplayString();
      final methodName = method.displayName;

      // Если список параметров длинный — переносим вызов на новую строку для читаемости.
      final hasLongArgs = args.length > 60 || args.contains('\n');
      if (hasLongArgs) {
        buffer.write('    bind<$returnType>()\n'
            '      .toProvide(\n        () => $methodName($args))');
      } else {
        buffer.write('    bind<$returnType>()'
            '.toProvide(() => $methodName($args))');
      }
      // Применяем имя биндера если есть @named
      if (nameArg != null) {
        buffer.write(".withName('$nameArg')");
      }
      // Применяем singleton если был @singleton
      if (hasSingleton) {
        buffer.write('.singleton()');
      }
      buffer.write(';\n');
    }

    buffer.writeln('  }');
    buffer.writeln('}');

    return buffer.toString();
  }
}

/// Фабрика Builder-го класса для build_runner
/// Генерирует .cherrypick.g.dart файл для каждого модуля.
Builder moduleBuilder(BuilderOptions options) =>
    PartBuilder([ModuleGenerator()], '.cherrypick.g.dart');
