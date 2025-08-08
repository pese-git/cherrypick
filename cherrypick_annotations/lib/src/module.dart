//
// Copyright 2021 Sergey Penkovsky (sergey.penkovsky@gmail.com)
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//      https://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

/// ENGLISH:
/// Annotation for marking Dart classes or libraries as modules.
///
/// Use the `@module()` annotation on abstract classes (or on a library)
/// to indicate that the class represents a DI (Dependency Injection) module.
/// This is commonly used in code generation tools to automatically register
/// and configure dependencies defined within the module.
///
/// Example:
/// ```dart
/// @module()
/// abstract class AppModule extends Module {
///   // Dependency definitions go here.
/// }
/// ```
///
/// Generates code like:
/// ```dart
/// final class $AppModule extends AppModule {
///   @override
///   void builder(Scope currentScope) {
///     // Dependency registration...
///   }
/// }
/// ```
///
/// RUSSIAN (Русский):
/// Аннотация для пометки классов или библиотек Dart как модуля.
///
/// Используйте `@module()` для абстрактных классов (или библиотек), чтобы
/// показать, что класс реализует DI-модуль (Dependency Injection).
/// Обычно используется генераторами кода для автоматической регистрации
/// и конфигурирования зависимостей, определённых в модуле.
///
/// Пример:
/// ```dart
/// @module()
/// abstract class AppModule extends Module {
///   // Определения зависимостей
/// }
/// ```
///
/// Будет сгенерирован код:
/// ```dart
/// final class $AppModule extends AppModule {
///   @override
///   void builder(Scope currentScope) {
///     // Регистрация зависимостей...
///   }
/// }
/// ```
// ignore: camel_case_types
final class module {
  /// Creates a [module] annotation.
  const module();
}
