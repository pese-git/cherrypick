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

/// ENGLISH:
/// Annotation to declare a factory/provider method or class as a singleton.
///
/// Use the `@singleton()` annotation on methods in your DI module to specify
/// that only one instance of the resulting object should be created and shared
/// for all consumers. This is especially useful in dependency injection
/// frameworks and service locators.
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
/// This generates the following code:
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
/// Аннотация для объявления фабричного/провайдерного метода или класса синглтоном.
///
/// Используйте `@singleton()` для методов внутри DI-модуля, чтобы указать,
/// что соответствующий объект (экземпляр класса) должен быть создан только один раз
/// и использоваться всеми компонентами приложения (единый общий экземпляр).
/// Это характерно для систем внедрения зависимостей и сервис-локаторов.
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
final class provide {
  const provide();
}
