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
/// Annotation to assign a name or identifier to a class, method, or other element.
///
/// The `@named('value')` annotation allows you to specify a string name
/// for a dependency, factory, or injectable. This is useful for distinguishing
/// between multiple registrations of the same type in dependency injection,
/// code generation, and for providing human-readable metadata.
///
/// Example:
/// ```dart
/// @module()
/// abstract class AppModule extends Module {
///   @named('dio')
///   Dio dio() => Dio();
/// }
/// ```
///
/// This will generate:
/// ```dart
/// final class $AppModule extends AppModule {
///   @override
///   void builder(Scope currentScope) {
///     bind<Dio>().toProvide(() => dio()).withName('dio').singleton();
///   }
/// }
/// ```
///
/// RUSSIAN (Русский):
/// Аннотация для задания имени или идентификатора классу, методу или другому элементу.
///
/// Аннотация `@named('значение')` позволяет указать строковое имя для зависимости,
/// фабрики или внедряемого значения. Это удобно для различения нескольких
/// регистраций одного типа в DI, генерации кода.
///
/// Пример:
/// ```dart
/// @module()
/// abstract class AppModule extends Module {
///   @named('dio')
///   Dio dio() => Dio();
/// }
/// ```
///
/// Будет сгенерирован следующий код:
/// ```dart
/// final class $AppModule extends AppModule {
///   @override
///   void builder(Scope currentScope) {
///     bind<Dio>().toProvide(() => dio()).withName('dio').singleton();
///   }
/// }
/// ```
// ignore: camel_case_types
final class named {
  /// EN: The assigned name or identifier for the element.
  ///
  /// RU: Назначенное имя или идентификатор для элемента.
  final String value;

  /// EN: Creates a [named] annotation with the given [value].
  ///
  /// RU: Создаёт аннотацию [named] с заданным значением [value].
  const named(this.value);
}
