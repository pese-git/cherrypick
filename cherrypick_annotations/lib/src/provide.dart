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

/// Marks a method or class as a dependency provider (factory/provider) for CherryPick module code generation.
///
/// Use `@provide` on any method inside a `@module()` annotated class when you want that method
/// to be used as a DI factory/provider during code generation.
///
/// This should be used for methods that create dynamic, optional, or complex dependencies, especially
/// if you want to control the codegen/injection pipeline explicitly and support parameters.
///
/// Example:
/// ```dart
/// import 'package:cherrypick_annotations/cherrypick_annotations.dart';
///
/// @module()
/// abstract class FeatureModule {
///   @provide
///   Future<Api> provideApi(@params Map<String, dynamic> args) async => ...;
///
///   @singleton()
///   @provide
///   Logger provideLogger() => Logger();
/// }
/// ```
///
/// See also: [@singleton], [@instance], [@params], [@named]
@experimental
final class provide {
  /// Creates a [provide] annotation for marking provider methods/classes in DI modules.
  const provide();
}
