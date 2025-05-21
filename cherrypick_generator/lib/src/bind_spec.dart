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

import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

import 'bind_parameters_spec.dart';
import 'metadata_utils.dart';

///
/// Описывает параметры для создания одного биндинга зависимости (binding spec).
///
/// Каждый биндинг соответствует одному публичному методу класса-модуля.
///
class BindSpec {
  /// Тип, который предоставляет биндинг (например, SomeService)
  final String returnType;

  /// Имя метода, который реализует биндинг
  final String methodName;

  /// Необязательное имя, для именованной зависимости (используется с @named)
  final String? named;

  /// Является ли зависимость синглтоном (имеется ли аннотация @singleton)
  final bool isSingleton;

  /// Список параметров, которые требуются методу для внедрения зависимостей
  final List<BindParameterSpec> parameters;

  final String bindingType; // 'instance' | 'provide'

  final bool isAsyncInstance;

  final bool isAsyncProvide;

  final bool hasParams;

  BindSpec({
    required this.returnType,
    required this.methodName,
    required this.isSingleton,
    required this.parameters,
    this.named,
    required this.bindingType,
    required this.isAsyncInstance,
    required this.isAsyncProvide,
    required this.hasParams,
  });

  /// Формирует dart-код для биндинга, например:
  ///   bind<Type>().toProvide(() => method(args)).withName('name').singleton();
  ///
  /// Параметр [indent] задаёт отступ для красивого форматирования кода.
  String generateBind(int indent) {
    final indentStr = ' ' * indent;

    // Если есть @params()
    const paramVar = 'args'; // <= новое имя для безопасности

    if (hasParams) {
      final fnArgs = parameters
          .map((p) => p.isParams ? paramVar : p.generateArg(paramVar))
          .join(', ');
      String provide;
      if (bindingType == 'instance') {
        provide = isAsyncInstance
            ? '.toInstanceAsync(($fnArgs) => $methodName($fnArgs))'
            : '.toInstance(($fnArgs) => $methodName($fnArgs))';
      } else if (isAsyncProvide) {
        provide = (fnArgs.length > 60 || fnArgs.contains('\n'))
            ? '.toProvideAsyncWithParams(\n${' ' * (indent + 2)}($paramVar) => $methodName($fnArgs))'
            : '.toProvideAsyncWithParams(($paramVar) => $methodName($fnArgs))';
      } else {
        provide = (fnArgs.length > 60 || fnArgs.contains('\n'))
            ? '.toProvideWithParams(\n${' ' * (indent + 2)}($paramVar) => $methodName($fnArgs))'
            : '.toProvideWithParams(($paramVar) => $methodName($fnArgs))';
      }
      final namePart = named != null ? ".withName('$named')" : '';
      final singletonPart = isSingleton ? '.singleton()' : '';
      return '$indentStr'
          'bind<$returnType>()'
          '$provide'
          '$namePart'
          '$singletonPart;';
    }

    // Собираем строку аргументов для вызова метода
    final argsStr = parameters.map((p) => p.generateArg()).join(', ');

    // Если аргументов много или они длинные — разбиваем вызов на несколько строк
    //final needMultiline = argsStr.length > 60 || argsStr.contains('\n');

    String provide;
    if (bindingType == 'instance') {
      // Добавляем async вариант для Future<T>
      if (isAsyncInstance) {
        provide = '.toInstanceAsync($methodName($argsStr))';
      } else {
        provide = '.toInstance($methodName($argsStr))';
      }
    } else {
      // provide
      if (isAsyncProvide) {
        // Асинхронная фабрика
        provide = (argsStr.length > 60 || argsStr.contains('\n'))
            ? '.toProvideAsync(\n${' ' * (indent + 2)}() => $methodName($argsStr))'
            : '.toProvideAsync(() => $methodName($argsStr))';
      } else {
        provide = (argsStr.length > 60 || argsStr.contains('\n'))
            ? '.toProvide(\n${' ' * (indent + 2)}() => $methodName($argsStr))'
            : '.toProvide(() => $methodName($argsStr))';
      }
    }

    final namePart = named != null ? ".withName('$named')" : '';
    final singletonPart = isSingleton ? '.singleton()' : '';

    // Итоговый bind: bind<Type>().toProvide(...).withName(...).singleton();
    return '$indentStr'
        'bind<$returnType>()'
        '$provide'
        '$namePart'
        '$singletonPart;';
    // Всегда заканчиваем точкой с запятой!
  }

  /// Создаёт спецификацию биндинга (BindSpec) из метода класса-модуля
  static BindSpec fromMethod(MethodElement method) {
    var returnType = method.returnType.getDisplayString();

    final methodName = method.displayName;
    // Проверим, помечен ли метод аннотацией @singleton
    final isSingleton = MetadataUtils.anyMeta(method.metadata, 'singleton');

    // Получаем имя из @named(), если есть
    final named = MetadataUtils.getNamedValue(method.metadata);

    // Для каждого параметра метода
    final params = <BindParameterSpec>[];
    bool hasParams = false;
    for (final p in method.parameters) {
      final typeStr = p.type.getDisplayString();
      final paramNamed = MetadataUtils.getNamedValue(p.metadata);
      final isParams = MetadataUtils.anyMeta(p.metadata, 'params');
      if (isParams) hasParams = true;
      params.add(BindParameterSpec(typeStr, paramNamed, isParams: isParams));
    }

    // определяем bindingType
    final hasInstance = MetadataUtils.anyMeta(method.metadata, 'instance');
    final hasProvide = MetadataUtils.anyMeta(method.metadata, 'provide');
    if (!hasInstance && !hasProvide) {
      throw InvalidGenerationSourceError(
        'Метод $methodName класса-модуля должен быть помечен либо @instance(), либо @provide().',
        element: method,
      );
    }
    final bindingType = hasInstance ? 'instance' : 'provide';

    // --- Новый участок: извлекаем внутренний тип из Future<> и выставляем флаги
    bool isAsyncInstance = false;
    bool isAsyncProvide = false;

    if (returnType.startsWith('Future<')) {
      final futureMatch = RegExp(r'^Future<(.+)>$').firstMatch(returnType);
      if (futureMatch != null) {
        returnType = futureMatch.group(1)!.trim();
        if (bindingType == 'instance') isAsyncInstance = true;
        if (bindingType == 'provide') isAsyncProvide = true;
      }
    }

    return BindSpec(
      returnType: returnType,
      methodName: methodName,
      isSingleton: isSingleton,
      named: named,
      parameters: params,
      bindingType: bindingType,
      isAsyncInstance: isAsyncInstance,
      isAsyncProvide: isAsyncProvide,
      hasParams: hasParams,
    );
  }
}
