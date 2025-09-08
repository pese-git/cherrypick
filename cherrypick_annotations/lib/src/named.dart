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

/// Assigns a name or key identifier to a class, field, factory method or parameter
/// for use in multi-registration scenarios (named dependencies) in CherryPick DI.
///
/// Use `@named('key')` to distinguish between multiple bindings/implementations
/// of the same type—when registering and when injecting dependencies.
///
/// You can use `@named`:
/// - On provider/factory methods in a module
/// - On fields with `@inject()` to receive a named instance
/// - On function parameters (for method/constructor injection)
///
/// ### Example: On Provider Method
/// ```dart
/// @module()
/// abstract class AppModule {
///   @named('main')
///   ApiClient apiClient() => ApiClient();
///
///   @named('mock')
///   ApiClient mockApi() => MockApiClient();
/// }
/// ```
///
/// ### Example: On Injectable Field
/// ```dart
/// @injectable()
/// class WidgetModel with _\$WidgetModel {
///   @inject()
///   @named('main')
///   late final ApiClient api;
/// }
/// ```
///
/// ### Example: On Parameter
/// ```dart
/// class UserScreen {
///   UserScreen(@named('current') User user);
/// }
/// ```
@experimental
final class named {
  /// The assigned name or identifier for the dependency, provider, or parameter.
  final String value;

  /// Creates a [named] annotation with the given [value] key or name.
  const named(this.value);
}
