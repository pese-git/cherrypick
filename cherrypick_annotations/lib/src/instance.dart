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

/// Marks a provider method or class to always create a new instance (factory) in CherryPick DI.
///
/// Use `@instance()` to annotate methods or classes in your DI module/class
/// when you want a new object to be created on every injection (no singleton caching).
/// The default DI lifecycle is instance/factory unless otherwise specified.
///
/// ### Example (in a module method)
/// ```dart
/// import 'package:cherrypick_annotations/cherrypick_annotations.dart';
///
/// @module()
/// abstract class FeatureModule {
///   @instance()
///   MyService provideService() => MyService();
///
///   @singleton()
///   Logger provideLogger() => Logger();
/// }
/// ```
///
/// ### Example (on a class, with @injectable)
/// ```dart
/// @injectable()
/// @instance()
/// class MyFactoryClass {
///   // ...
/// }
/// ```
///
/// See also: [@singleton]
@experimental
final class instance {
  /// Creates an [instance] annotation for classes or providers.
  const instance();
}
