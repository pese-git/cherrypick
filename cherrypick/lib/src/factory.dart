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
import 'package:cherrypick/src/scope.dart';

/// Abstract factory interface for creating objects of type [T] using a [Scope].
///
/// Can be implemented for advanced dependency injection scenarios where
/// the resolution requires contextual information from the DI [Scope].
///
/// Often used to supply complex objects, runtime-bound services,
/// or objects depending on dynamic configuration.
///
/// Example usage:
/// ```dart
/// class MyServiceFactory implements Factory<MyService> {
///   @override
///   MyService createInstance(Scope scope) {
///     final db = scope.resolve<Database>(named: "main");
///     return MyService(db);
///   }
/// }
///
/// // Usage in a module:
/// bind<MyService>().toProvide(() => MyServiceFactory().createInstance(scope));
/// ```
abstract class Factory<T> {
  /// Implement this to provide an instance of [T], with access to the resolving [scope].
  T createInstance(Scope scope);
}
