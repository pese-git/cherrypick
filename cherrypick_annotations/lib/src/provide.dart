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

/// An annotation to indicate that a method provides a dependency to the module.
///
/// This annotation is typically used in conjunction with dependency injection,
/// marking methods whose return value should be registered as a provider.
/// The annotated method can optionally declare dependencies as parameters,
/// which will be resolved and injected automatically.
///
/// Example:
/// ```dart
/// @module()
/// abstract class AppModule extends Module {
///   @provide()
///   Foo foo(Bar bar) => Foo(bar);
/// }
/// ```
///
/// This will generate:
/// ```dart
/// final class $AppModule extends AppModule {
///   @override
///   void builder(Scope currentScope) {
///     bind<Foo>().toProvide(() => foo(currentScope.resolve<Bar>()));
///   }
/// }
/// ```
// ignore: camel_case_types
final class provide {
  const provide();
}
