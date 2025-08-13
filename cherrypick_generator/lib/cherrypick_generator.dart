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
library;

/// CherryPick code generation library: entry point for build_runner DI codegen.
///
/// This library exports generators for CherryPick dependency injection:
/// - [ModuleGenerator]: Generates DI module classes for all `@module()`-annotated classes.
/// - [InjectGenerator]: Generates field-injection mixins for classes annotated with `@injectable()`.
///
/// These generators are hooked into [build_runner] and cherrypick_generator's builder configuration.
/// Normally you do not import this directly; instead, add cherrypick_generator
/// as a dev_dependency and run `dart run build_runner build`.
///
/// Example usage in `build.yaml` or your project's workflow:
/// ```yaml
/// targets:
///   $default:
///     builders:
///       cherrypick_generator|cherrypick_generator:
///         generate_for:
///           - lib/**.dart
/// ```
///
/// For annotation details, see `package:cherrypick_annotations`.
export 'module_generator.dart';
export 'inject_generator.dart';
