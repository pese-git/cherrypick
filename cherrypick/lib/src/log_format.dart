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


/// Ёдиный форматтер лог-сообщений CherryPick.
///
/// Используйте для формирования сообщений всех уровней (info, warn, error)
/// Например:
///   log.info(formatLogMessage(type:'Binding', name:..., params:{...}, description:'created'));

String formatLogMessage({
  required String type,        // Binding, Scope, Module, ...
  String? name,               // Имя binding/scope/module
  Map<String, Object?>? params, // Дополнительные параметры (id, parent, named и др.)
  required String description,   // Краткое описание события
}) {
  final label = name != null ? '$type:$name' : type;
  final paramsStr = (params != null && params.isNotEmpty)
      ? params.entries.map((e) => '${e.key}=${e.value}').join(' ')
      : '';
  return '[$label]'
         '${paramsStr.isNotEmpty ? ' $paramsStr' : ''}'
         ' $description';
}
