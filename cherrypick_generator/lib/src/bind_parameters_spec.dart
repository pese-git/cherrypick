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

///
/// Описывает один параметр метода и возможность его разрешения из контейнера.
///
/// Например, если метод принимает SomeDep dep, то
/// BindParameterSpec хранит тип SomeDep, а generateArg отдаст строку
///   currentScope.resolve<SomeDep>()
///
class BindParameterSpec {
  /// Имя типа параметра (например, SomeService)
  final String typeName;

  /// Необязательное имя для разрешения по имени (если аннотировано через @named)
  final String? named;

  final bool isParams;

  BindParameterSpec(this.typeName, this.named, {this.isParams = false});

  /// Генерирует строку для получения зависимости из DI scope (с учётом имени)
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
