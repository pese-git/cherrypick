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

/// Marks a parameter in a provider method to receive dynamic runtime arguments when resolving a dependency.
///
/// Use `@params()` in a DI module/factory method when the value must be supplied by the user/code at injection time,
/// not during static wiring (such as user input, navigation arguments, etc).
///
/// This enables CherryPick and its codegen to generate .withParams or .toProvideWithParams bindings — so your provider can access runtime values.
///
/// Example:
/// ```dart
/// import 'package:cherrypick_annotations/cherrypick_annotations.dart';
///
/// @module()
/// abstract class FeatureModule {
///   @provide
///   UserManager createManager(@params Map<String, dynamic> runtimeParams) {
///     return UserManager.forUserId(runtimeParams['userId']);
///   }
/// }
/// ```
/// Usage at injection/resolution:
/// ```dart
/// final manager = scope.resolve<UserManager>(params: {'userId': myId});
/// ```
@experimental
final class params {
  /// Marks a method/constructor parameter as supplied at runtime by the caller.
  const params();
}
