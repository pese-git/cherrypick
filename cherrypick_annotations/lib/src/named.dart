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

/// An annotation to assign a name or identifier to a class, method, or other element.
///
/// This can be useful for code generation, dependency injection,
/// or providing metadata within a framework.
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
/// Сгенерирует код:
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
  /// The assigned name or identifier.
  final String value;

  /// Creates a [named] annotation with the given [value].
  const named(this.value);
}
