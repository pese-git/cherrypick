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

/// An annotation to declare a class as a singleton.
///
/// This can be used to indicate that only one instance of the class
/// should be created, which is often useful in dependency injection
/// frameworks or service locators.
///
/// Example:
/// ```dart
/// @module()
/// abstract class AppModule extends Module {
///   @singleton()
///   Dio dio() => Dio();
/// }
/// ```
/// Сгенерирует код:
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
