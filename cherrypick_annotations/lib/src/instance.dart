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
/// Annotation to specify that a new instance should be provided on each request.
///
/// Use the `@instance()` annotation for methods or classes in your DI module
/// to declare that the DI container must create a new object every time
/// the dependency is injected (i.e., no singleton behavior).
///
/// Example:
/// ```dart
/// @module()
/// abstract class AppModule extends Module {
///   @instance()
///   Foo foo() => Foo();
/// }
/// ```
///
/// This will generate:
/// ```dart
/// final class $AppModule extends AppModule {
///   @override
///   void builder(Scope currentScope) {
///     bind<Foo>().toInstance(() => foo());
///   }
/// }
/// ```
///
/// RUSSIAN (Русский):
/// Аннотация для создания нового экземпляра при каждом запросе.
///
/// Используйте `@instance()` для методов или классов в DI-модуле,
/// чтобы указать, что контейнер внедрения зависимостей должен создавать
/// новый объект при каждом обращении к зависимости (то есть, не синглтон).
///
/// Пример:
/// ```dart
/// @module()
/// abstract class AppModule extends Module {
///   @instance()
///   Foo foo() => Foo();
/// }
/// ```
///
/// Будет сгенерирован следующий код:
/// ```dart
/// final class $AppModule extends AppModule {
///   @override
///   void builder(Scope currentScope) {
///     bind<Foo>().toInstance(() => foo());
///   }
/// }
/// ```
// ignore: camel_case_types
final class instance {
  const instance();
}
