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

/// Marks a class as injectable for the CherryPick dependency injection framework.
/// If a class is annotated with [@injectable()], the code generator will
/// create a mixin to perform automatic injection of fields marked with [@inject].
///
/// ---
///
/// Помечает класс как внедряемый для фреймворка внедрения зависимостей CherryPick.
/// Если класс помечен аннотацией [@injectable()], генератор создаст миксин
/// для автоматического внедрения полей, отмеченных [@inject].
///
/// Example / Пример:
/// ```dart
/// @injectable()
/// class MyWidget extends StatelessWidget {
///   @inject()
///   late final MyService service;
/// }
/// ```
@experimental
// ignore: camel_case_types
final class injectable {
  const injectable();
}
