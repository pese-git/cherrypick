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
import 'src/generated_class.dart';
import 'cherrypick_custom_builders.dart' as custom;
/// ---------------------------------------------------------------------------
/// ModuleGenerator for code generation of dependency-injected modules.
///
/// ENGLISH
/// This generator scans for Dart classes annotated with `@module()` and
/// automatically generates boilerplate code for dependency injection
/// (DI) based on the public methods in those classes. Each method can be
/// annotated to describe how an object should be provided to the DI container.
/// The generated code registers those methods as bindings. This automates the
/// creation of factories, singletons, and named instances, reducing repetitive
/// manual code.
///
/// RUSSIAN
/// Генератор зависимостей для DI-контейнера на основе аннотаций.
/// Данный генератор автоматически создаёт код для внедрения зависимостей (DI)
/// на основе аннотаций в вашем исходном коде. Когда вы отмечаете класс
/// аннотацией `@module()`, этот генератор обработает все его публичные методы
/// и автоматически сгенерирует класс с биндингами (регистрациями зависимостей)
/// для DI-контейнера. Это избавляет от написания однообразного шаблонного кода.
/// ---------------------------------------------------------------------------

class ModuleGenerator extends GeneratorForAnnotation<ann.module> {
  /// -------------------------------------------------------------------------
  /// ENGLISH
  /// Generates the Dart source for a class marked with the `@module()` annotation.
  /// - [element]: the original Dart class element.
  /// - [annotation]: the annotation parameters (not usually used here).
  /// - [buildStep]: the current build step info.
  ///
  /// RUSSIAN
  /// Генерирует исходный код для класса-модуля с аннотацией `@module()`.
  /// [element] — исходный класс, помеченный аннотацией.
  /// [annotation] — значения параметров аннотации.
  /// [buildStep] — информация о текущем шаге генерации.
  /// -------------------------------------------------------------------------
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    // Only classes are supported for @module() annotation
    // Обрабатываются только классы (другие элементы — ошибка)
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@module() can only be applied to classes. / @module() может быть применён только к классам.',
        element: element,
      );
    }

    final classElement = element;

    // Build a representation of the generated bindings based on class methods /
    // Создаёт объект, описывающий, какие биндинги нужно сгенерировать на основании методов класса
    final generatedClass = GeneratedClass.fromClassElement(classElement);

    // Generate the resulting Dart code / Генерирует итоговый Dart-код
    return generatedClass.generate();
  }
}

/// ---------------------------------------------------------------------------
/// ENGLISH
/// Entry point for build_runner. Returns a Builder used to generate code for
/// every file with a @module() annotation.
///
/// RUSSIAN
/// Точка входа для генератора build_runner.
/// Возвращает Builder, используемый build_runner для генерации кода для всех
/// файлов, где встречается @module().
/// ---------------------------------------------------------------------------



Builder moduleBuilder(BuilderOptions options) =>
    custom.moduleCustomBuilder(options);