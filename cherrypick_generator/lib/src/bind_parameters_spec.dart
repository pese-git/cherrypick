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

/// ----------------------------------------------------------------------------
/// BindParameterSpec - describes a single method parameter and how to resolve it.
///
/// ENGLISH
/// Describes a single parameter for a provider/binding method in the DI system.
/// Stores the parameter type, its optional `@named` key for named resolution,
/// and whether it is a runtime "params" argument. Used to generate code that
/// resolves dependencies from the DI scope:
///   - If the parameter is a dependency type (e.g. SomeDep), emits:
///         currentScope.resolve<SomeDep>()
///   - If the parameter is named, emits:
///         currentScope.resolve<SomeDep>(named: 'yourName')
///   - If it's a runtime parameter (e.g. via @params()), emits:
///         args
///
/// RUSSIAN
/// Описывает один параметр метода в DI, и его способ разрешения из контейнера.
/// Сохраняет имя типа, дополнительное имя (если параметр аннотирован через @named),
/// и признак runtime-параметра (@params).
/// Для обычной зависимости типа (например, SomeDep) генерирует строку вида:
///   currentScope.resolve<SomeDep>()
/// Для зависимости с именем:
///   currentScope.resolve<SomeDep>(named: 'имя')
/// Для runtime-параметра:
///   args
/// ----------------------------------------------------------------------------
class BindParameterSpec {
  /// Type name of the parameter (e.g. SomeService)
  /// Имя типа параметра (например, SomeService)
  final String typeName;

  /// Optional name for named resolution (from @named)
  /// Необязательное имя для разрешения по имени (если аннотировано через @named)
  final String? named;

  /// True if this parameter uses @params and should be provided from runtime args
  /// Признак, что параметр — runtime (через @params)
  final bool isParams;

  BindParameterSpec(this.typeName, this.named, {this.isParams = false});

  /// --------------------------------------------------------------------------
  /// generateArg
  ///
  /// ENGLISH
  /// Generates Dart code for resolving the dependency from the DI scope,
  /// considering type, named, and param-argument.
  ///
  /// RUSSIAN
  /// Генерирует строку для получения зависимости из DI scope (с учётом имени
  /// и типа параметра или runtime-режима @params).
  /// --------------------------------------------------------------------------
  String generateArg([String paramsVar = 'args']) {
    if (isParams) {
      return paramsVar;
    }
    if (named != null) {
      return "currentScope.resolve<$typeName>(named: '$named')";
    }
    return "currentScope.resolve<$typeName>()";
  }
}
