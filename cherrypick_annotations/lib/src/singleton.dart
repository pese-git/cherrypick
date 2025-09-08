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

/// Marks a provider method or class so its instance is created only once and shared (singleton) for DI in CherryPick.
///
/// Use `@singleton()` on provider methods or classes in your DI module to ensure only one instance is ever created
/// and reused across the application's lifetime (or scope lifetime).
///
/// Example:
/// ```dart
/// import 'package:cherrypick_annotations/cherrypick_annotations.dart';
///
/// @module()
/// abstract class AppModule {
///   @singleton()
///   ApiClient createApi() => ApiClient();
/// }
/// ```
///
/// The generated code will ensure:
/// ```dart
/// bind<ApiClient>().toProvide(() => createApi()).singleton();
/// ```
///
/// See also: [@instance], [@provide], [@named]
@experimental
final class singleton {
  /// Creates a [singleton] annotation for DI providers/classes.
  const singleton();
}
