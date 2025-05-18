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

/// An annotation used to mark a Dart class or library as a module.
///
/// This annotation can be used for tooling, code generation,
/// or to provide additional metadata about the module.
///
/// Example:
/// ```dart
/// @module()
/// abstract class AppModule extends Module {
/// }
/// ```
/// Сгенерирует код:
/// ```dart
/// final class $AppModule extends AppModule {
///   @override
///   void builder(Scope currentScope) {
///
///   }
/// }
// ignore: camel_case_types
final class module {
  /// Creates a [module] annotation.
  const module();
}
