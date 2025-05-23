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

/// ENGLISH:
/// Annotation to mark a method parameter for injection with run-time arguments.
///
/// Use the `@params()` annotation to specify that a particular parameter of a
/// provider method should be assigned a value supplied at resolution time,
/// rather than during static dependency graph creation. This is useful in DI
/// when a dependency must receive dynamic data passed by the consumer
/// (via `.withParams(...)` in the generated code).
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
///
/// RUSSIAN (Русский):
/// Аннотация для пометки параметра метода, который будет внедряться со значением во время выполнения.
///
/// Используйте `@params()` чтобы указать, что конкретный параметр метода-провайдера
/// должен получать значение, передаваемое в момент обращения к зависимости,
/// а не на этапе построения графа зависимостей. Это полезно, если зависимость
/// должна получать данные динамически от пользователя или другого процесса
/// через `.withParams(...)` в сгенерированном коде.
///
/// Пример:
/// ```dart
/// @provide()
/// String greet(@params() dynamic params) => 'Hello $params';
/// ```
///
/// Будет сгенерировано:
/// ```dart
/// bind<String>().toProvideWithParams((args) => greet(args));
/// ```
// ignore: camel_case_types
final class params {
  const params();
}
