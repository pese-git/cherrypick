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

/// An annotation to specify that a method or class provides a new instance
/// each time it is requested.
///
/// This is typically used to indicate that the annotated binding should
/// not be a singleton and a new object is created for every injection.
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
// ignore: camel_case_types
final class instance {
  const instance();
}
