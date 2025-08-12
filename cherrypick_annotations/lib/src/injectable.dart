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

/// Marks a class as injectable, enabling automatic field injection by CherryPick's code generator.
///
/// Use `@injectable()` on a class whose fields (marked with `@inject`) you want to be automatically injected from the DI [Scope].
/// When used together with code generation (see cherrypick_generator), a mixin will be generated to inject fields.
///
/// Example:
/// ```dart
/// import 'package:cherrypick_annotations/cherrypick_annotations.dart';
///
/// @injectable()
/// class ProfileScreen with _\$ProfileScreen {
///   @inject()
///   late final UserManager manager;
///
///   @inject()
///   @named('main')
///   late final ApiClient api;
/// }
///
/// // After running build_runner, call:
/// // profileScreen.injectFields();
/// ```
///
/// After running the generator, the mixin (`_\$ProfileScreen`) will be available to help auto-inject all [@inject] fields in your widget/service/controller.
@experimental
final class injectable {
  const injectable();
}
