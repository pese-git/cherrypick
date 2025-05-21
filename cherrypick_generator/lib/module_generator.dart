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

///
/// Генератор зависимостей для DI-контейнера на основе аннотаций.
///
/// Данный генератор автоматически создаёт код для внедрения зависимостей (DI)
/// на основе аннотаций в вашем исходном коде. Когда вы отмечаете класс
/// аннотацией `@module()`, этот генератор обработает все его публичные методы
/// и автоматически сгенерирует класс с биндингами (регистрациями зависимостей)
/// для DI-контейнера. Это избавляет от написания однообразного шаблонного кода.
///
class ModuleGenerator extends GeneratorForAnnotation<ann.module> {
  /// Генерирует исходный код для класса-модуля с аннотацией `@module()`.
  ///
  /// [element] — исходный класс, помеченный аннотацией.
  /// [annotation] — значения параметров аннотации.
  /// [buildStep] — информация о текущем шаге генерации.
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    // Генератор обрабатывает только классы (остальное — ошибка)
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@module() может быть применён только к классам.',
        element: element,
      );
    }

    final classElement = element;

    // Создаёт объект, описывающий, какие биндинги нужно сгенерировать на основании методов класса
    final generatedClass = GeneratedClass.fromClassElement(classElement);

    // Генерирует итоговый Dart-код
    return generatedClass.generate();
  }
}

///
/// Точка входа для генератора build_runner.
/// Возвращает Builder, используемый build_runner для генерации кода для всех
/// файлов, где встречается @module().
///
Builder moduleBuilder(BuilderOptions options) =>
    PartBuilder([ModuleGenerator()], '.cherrypick.g.dart');
