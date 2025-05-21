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

///
/// Результат обработки одного класса-модуля: имя класса, его биндинги,
/// имя генерируемого класса и т.д.
///
class GeneratedClass {
  /// Имя исходного класса-модуля
  final String className;

  /// Имя генерируемого класса (например, $SomeModule)
  final String generatedClassName;

  /// Список всех обнаруженных биндингов
  final List<BindSpec> binds;

  GeneratedClass(
    this.className,
    this.generatedClassName,
    this.binds,
  );

  /// Обрабатывает объект ClassElement (отображение класса в AST)
  /// и строит структуру _GeneratedClass для генерации кода.
  static GeneratedClass fromClassElement(ClassElement element) {
    final className = element.displayName;
    // Имя с префиксом $ (стандартная практика для ген-кода)
    final generatedClassName = r'$' + className;
    // Собираем биндинги по всем методам класса, игнорируем абстрактные (без реализации)
    final binds = element.methods
        .where((m) => !m.isAbstract)
        .map(BindSpec.fromMethod)
        .toList();

    return GeneratedClass(className, generatedClassName, binds);
  }

  /// Генерирует исходный Dart-код для созданного класса DI-модуля.
  ///
  /// Внутри builder(Scope currentScope) регистрируются все bind-методы.
  String generate() {
    final buffer = StringBuffer();

    buffer.writeln('final class $generatedClassName extends $className {');
    buffer.writeln(' @override');
    buffer.writeln(' void builder(Scope currentScope) {');

    // Для каждого биндинга — генерируем строку bind<Type>()...
    for (final bind in binds) {
      buffer.writeln(bind.generateBind(4));
    }

    buffer.writeln(' }');
    buffer.writeln('}');

    return buffer.toString();
  }
}
