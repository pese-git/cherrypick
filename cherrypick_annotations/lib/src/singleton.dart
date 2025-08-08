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
/// Annotation to declare a dependency as a singleton.
///
/// Use the `@singleton()` annotation on provider methods inside a module
/// to indicate that only a single instance of this dependency should be
/// created and shared throughout the application's lifecycle. This is
/// typically used in dependency injection frameworks or service locators
/// to guarantee a single shared instance.
///
/// Example:
/// ```dart
/// @module()
/// abstract class AppModule extends Module {
///   @singleton()
///   Dio dio() => Dio();
/// }
/// ```
///
/// This will generate code like:
/// ```dart
/// final class $AppModule extends AppModule {
///   @override
///   void builder(Scope currentScope) {
///     bind<Dio>().toProvide(() => dio()).singleton();
///   }
/// }
/// ```
///
/// RUSSIAN (Русский):
/// Аннотация для объявления зависимости как синглтона.
///
/// Используйте `@singleton()` для методов-провайдеров внутри модуля,
/// чтобы указать, что соответствующий объект должен быть создан
/// единожды и использоваться во всём приложении (общий синглтон).
/// Это характерно для систем внедрения зависимостей и сервис-локаторов,
/// чтобы гарантировать один общий экземпляр.
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
/// Будет сгенерирован следующий код:
/// ```dart
/// final class $AppModule extends AppModule {
///   @override
///   void builder(Scope currentScope) {
///     bind<Dio>().toProvide(() => dio()).singleton();
///   }
/// }
/// ```
// ignore: camel_case_types
final class singleton {
  /// Creates a [singleton] annotation.
  const singleton();
}
