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
    final provide = _generateProvideClause(indent);
    final postfix = _generatePostfix();
    return '$indentStr'
        'bind<$returnType>()'
        '$provide'
        '$postfix;';
  }

  String _generateProvideClause(int indent) {
    if (hasParams) return _generateWithParamsProvideClause(indent);
    return _generatePlainProvideClause(indent);
  }

  String _generateWithParamsProvideClause(int indent) {
    // Безопасное имя для параметра
    const paramVar = 'args';
    final fnArgs = parameters
        .map((p) => p.isParams ? paramVar : p.generateArg(paramVar))
        .join(', ');
    final multiLine = fnArgs.length > 60 || fnArgs.contains('\n');
    switch (bindingType) {
      case 'instance':
        return isAsyncInstance
            ? '.toInstanceAsync(($fnArgs) => $methodName($fnArgs))'
            : '.toInstance(($fnArgs) => $methodName($fnArgs))';
      case 'provide':
      default:
        if (isAsyncProvide) {
          return multiLine
              ? '.toProvideAsyncWithParams(\n${' ' * (indent + 2)}($paramVar) => $methodName($fnArgs))'
              : '.toProvideAsyncWithParams(($paramVar) => $methodName($fnArgs))';
        } else {
          return multiLine
              ? '.toProvideWithParams(\n${' ' * (indent + 2)}($paramVar) => $methodName($fnArgs))'
              : '.toProvideWithParams(($paramVar) => $methodName($fnArgs))';
        }
    }
  }

  String _generatePlainProvideClause(int indent) {
    final argsStr = parameters.map((p) => p.generateArg()).join(', ');
    final multiLine = argsStr.length > 60 || argsStr.contains('\n');
    switch (bindingType) {
      case 'instance':
        return isAsyncInstance
            ? '.toInstanceAsync($methodName($argsStr))'
            : '.toInstance($methodName($argsStr))';
      case 'provide':
      default:
        if (isAsyncProvide) {
          return multiLine
              ? '.toProvideAsync(\n${' ' * (indent + 2)}() => $methodName($argsStr))'
              : '.toProvideAsync(() => $methodName($argsStr))';
        } else {
          return multiLine
              ? '.toProvide(\n${' ' * (indent + 2)}() => $methodName($argsStr))'
              : '.toProvide(() => $methodName($argsStr))';
        }
    }
  }

  String _generatePostfix() {
    final namePart = named != null ? ".withName('$named')" : '';
    final singletonPart = isSingleton ? '.singleton()' : '';
    return '$namePart$singletonPart';
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
    final futureInnerType = _extractFutureInnerType(returnType);
    if (futureInnerType != null) {
      returnType = futureInnerType;
      if (bindingType == 'instance') isAsyncInstance = true;
      if (bindingType == 'provide') isAsyncProvide = true;
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

  static String? _extractFutureInnerType(String typeName) {
    final match = RegExp(r'^Future<(.+)>$').firstMatch(typeName);
    return match?.group(1)?.trim();
  }
}
