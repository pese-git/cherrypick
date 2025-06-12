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

import 'bind_spec.dart';

/// ---------------------------------------------------------------------------
/// GeneratedClass -- represents the result of processing a single module class.
///
/// ENGLISH
/// Encapsulates all the information produced from analyzing a DI module class:
/// - The original class name,
/// - Its generated class name (e.g., `$SomeModule`),
/// - The collection of bindings (BindSpec) for all implemented provider methods.
///
/// Also provides code generation functionality, allowing to generate the source
/// code for the derived DI module class, including all binding registrations.
///
/// RUSSIAN
/// Описывает результат обработки одного класса-модуля DI:
/// - Имя оригинального класса,
/// - Имя генерируемого класса (например, `$SomeModule`),
/// - Список всех бидингов (BindSpec) — по публичным методам модуля.
///
/// Также содержит функцию генерации исходного кода для этого класса и
/// регистрации всех зависимостей через bind(...).
/// ---------------------------------------------------------------------------
class GeneratedClass {
  /// The name of the original module class.
  /// Имя исходного класса-модуля
  final String className;

  /// The name of the generated class (e.g., $SomeModule).
  /// Имя генерируемого класса (например, $SomeModule)
  final String generatedClassName;

  /// List of all discovered bindings for the class.
  /// Список всех обнаруженных биндингов
  final List<BindSpec> binds;

  GeneratedClass(
    this.className,
    this.generatedClassName,
    this.binds,
  );

  /// -------------------------------------------------------------------------
  /// fromClassElement
  ///
  /// ENGLISH
  /// Static factory: creates a GeneratedClass from a Dart ClassElement (AST representation).
  /// Discovers all non-abstract methods, builds BindSpec for each, and computes the
  /// generated class name by prefixing `$`.
  ///
  /// RUSSIAN
  /// Строит объект класса по элементу AST (ClassElement): имя класса,
  /// сгенерированное имя, список BindSpec по всем не абстрактным методам.
  /// Имя ген-класса строится с префиксом `$`.
  /// -------------------------------------------------------------------------
  static GeneratedClass fromClassElement(ClassElement element) {
    final className = element.displayName;
    // Generated class name with '$' prefix (standard for generated Dart code).
    final generatedClassName = r'$' + className;
    // Collect bindings for all non-abstract methods.
    final binds = element.methods
        .where((m) => !m.isAbstract)
        .map(BindSpec.fromMethod)
        .toList();

    return GeneratedClass(className, generatedClassName, binds);
  }

  /// -------------------------------------------------------------------------
  /// generate
  ///
  /// ENGLISH
  /// Generates Dart source code for the DI module class. The generated class
  /// inherits from the original, overrides the 'builder' method, and registers
  /// all bindings in the DI scope.
  ///
  /// RUSSIAN
  /// Генерирует исходный Dart-код для класса-модуля DI.
  /// Новая версия класса наследует оригинальный, переопределяет builder(Scope),
  /// и регистрирует все зависимости через методы bind<Type>()...
  /// -------------------------------------------------------------------------
  String generate() {
    final buffer = StringBuffer();

    buffer.writeln('final class $generatedClassName extends $className {');
    buffer.writeln(' @override');
    buffer.writeln(' void builder(Scope currentScope) {');

    // For each binding, generate bind<Type>() code string.
    // Для каждого биндинга — генерируем строку bind<Type>()...
    for (final bind in binds) {
      buffer.writeln(bind.generateBind(4));
    }

    buffer.writeln(' }');
    buffer.writeln('}');

    return buffer.toString();
  }
}
