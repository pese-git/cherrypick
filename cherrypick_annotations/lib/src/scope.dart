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

/// Specifies the DI scope or region from which a dependency should be resolved.
///
/// Use `@scope('scopeName')` on an injected field, parameter, or provider method when you want
/// to resolve a dependency not from the current scope, but from another named scope/subcontainer.
///
/// Useful for advanced DI scenarios: multi-feature/state isolation, navigation stacks, explicit subscopes, or testing.
///
/// Example (injected field):
/// ```dart
/// @injectable()
/// class ProfileScreen with _\$ProfileScreen {
///   @inject()
///   @scope('profile')
///   late final ProfileManager manager;
/// }
/// ```
///
/// Example (parameter):
/// ```dart
/// class TabBarModel {
///   TabBarModel(@scope('tabs') TabContext context);
/// }
/// ```
///
/// Example (in a module):
/// ```dart
/// @module()
/// abstract class FeatureModule {
///   @provide
///   Service service(@scope('shared') SharedConfig config);
/// }
/// ```
@experimental
final class scope {
  /// The name/key of the DI scope from which to resolve this dependency.
  final String? name;

  /// Creates a [scope] annotation specifying which DI scope to use for the dependency resolution.
  const scope(this.name);
}
