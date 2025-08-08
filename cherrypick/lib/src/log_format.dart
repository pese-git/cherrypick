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


/// Formats a log message string for CherryPick's logging system.
///
/// This function provides a unified structure for framework logs (info, warn, error, debug, etc.),
/// making it easier to parse and analyze events related to DI operations such as resolving bindings,
/// scope creation, module installation, etc.
///
/// All parameters except [name] and [params] are required.
///
/// Example:
/// ```dart
/// final msg = formatLogMessage(
///   type: 'Binding',
///   name: 'MyService',
///   params: {'parent': 'AppModule', 'lifecycle': 'singleton'},
///   description: 'created',
/// );
/// // Result: [Binding:MyService] parent=AppModule lifecycle=singleton created
/// ```
///
/// Parameters:
/// - [type]: The type of the log event subject (e.g., 'Binding', 'Scope', 'Module'). Required.
/// - [name]: Optional name of the subject (binding/scope/module) to disambiguate multiple instances/objects.
/// - [params]: Optional map for additional context (e.g., id, parent, lifecycle, named, etc.).
/// - [description]: Concise description of the event. Required.
///
/// Returns a structured string:
///   [type(:name)] param1=val1 param2=val2 ... description
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
