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

import 'package:meta/meta.dart';

/// Marks an abstract Dart class as a dependency injection module for CherryPick code generation.
///
/// Use `@module()` on your abstract class to indicate it provides DI bindings (via provider methods).
/// This enables code generation of a concrete module that registers all bindings from your methods.
///
/// Typical usage:
/// ```dart
/// import 'package:cherrypick_annotations/cherrypick_annotations.dart';
///
/// @module()
/// abstract class AppModule {
///   @singleton()
///   Logger provideLogger() => Logger();
///
///   @named('mock')
///   ApiClient mockApi() => MockApiClient();
/// }
/// ```
///
/// The generated code will look like:
/// ```dart
/// final class $AppModule extends AppModule {
///   @override
///   void builder(Scope currentScope) {
///     // Dependency registration code...
///   }
/// }
/// ```
///
/// See also: [@provide], [@singleton], [@instance], [@named]
@experimental
final class module {
  /// Creates a [module] annotation for use on a DI module class.
  const module();
}
