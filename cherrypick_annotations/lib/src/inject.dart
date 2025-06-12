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

import 'package:meta/meta.dart';

/// Annotation for field injection in CherryPick DI framework.
/// Apply this to a field, and the code generator will automatically inject
/// the appropriate dependency into it.
///
/// ---
///
/// Аннотация для внедрения зависимости в поле через фреймворк CherryPick DI.
/// Поместите её на поле класса — генератор кода автоматически подставит нужную зависимость.
///
/// Example / Пример:
/// ```dart
/// @inject()
/// late final SomeService service;
/// ```
@experimental
// ignore: camel_case_types
final class inject {
  const inject();
}
