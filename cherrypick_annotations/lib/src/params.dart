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

/// An annotation to indicate that a parameter is to be injected with run-time provided arguments.
///
/// Use this annotation to mark a method parameter that should receive arguments
/// passed during the resolution of a dependency (for example, through the
/// `.withParams(...)` method in the generated code).
///
/// Example:
/// ```dart
/// @provide()
/// String greet(@params() dynamic params) => 'Hello $params';
/// ```
///
/// This will generate:
/// ```dart
/// bind<String>().toProvideWithParams((args) => greet(args));
/// ```
// ignore: camel_case_types
final class params {
  const params();
}
