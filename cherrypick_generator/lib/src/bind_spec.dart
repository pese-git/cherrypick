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
import 'exceptions.dart';
import 'type_parser.dart';
import 'annotation_validator.dart';

enum BindingType {
  instance,
  provide;
}

/// ---------------------------------------------------------------------------
/// BindSpec -- describes a binding specification generated for a dependency.
///
/// ENGLISH
/// Represents all the data necessary to generate a DI binding for a single
/// method in a module class. Each BindSpec corresponds to one public method
/// and contains information about its type, provider method, lifecycle (singleton),
/// parameters (with their annotations), binding strategy (instance/provide),
/// asynchronous mode, and named keys. It is responsible for generating the
/// correct Dart code to register this binding with the DI container, in both
/// sync and async cases, with and without named or runtime arguments.
///
/// RUSSIAN
/// Описывает параметры для создания одного биндинга зависимости (binding spec).
/// Каждый биндинг соответствует одному публичному методу класса-модуля и
/// содержит всю информацию для генерации кода регистрации этого биндинга в
/// DI-контейнере: тип возвращаемой зависимости, имя метода, параметры, аннотации
/// (@singleton, @named, @instance, @provide), асинхронность, признак runtime
/// аргументов и др. Генерирует правильный Dart-код для регистрации биндера.
/// ---------------------------------------------------------------------------
class BindSpec {
  /// The type this binding provides (e.g. SomeService)
  /// Тип, который предоставляет биндинг (например, SomeService)
  final String returnType;

  /// Method name that implements the binding
  /// Имя метода, который реализует биндинг
  final String methodName;

  /// Optional name for named dependency (from @named)
  /// Необязательное имя, для именованной зависимости (используется с @named)
  final String? named;

  /// Whether the dependency is a singleton (@singleton annotation)
  /// Является ли зависимость синглтоном (имеется ли аннотация @singleton)
  final bool isSingleton;

  /// List of method parameters to inject dependencies with
  /// Список параметров, которые требуются методу для внедрения зависимостей
  final List<BindParameterSpec> parameters;

  /// Binding type: 'instance' or 'provide' (@instance or @provide)
  final BindingType bindingType; // 'instance' | 'provide'

  /// True if the method is asynchronous and uses instance binding (Future)
  final bool isAsyncInstance;

  /// True if the method is asynchronous and uses provide binding (Future)
  final bool isAsyncProvide;

  /// True if the binding method accepts runtime "params" argument (@params)
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

  /// -------------------------------------------------------------------------
  /// generateBind
  ///
  /// ENGLISH
  /// Generates a line of Dart code registering the binding with the DI framework.
  /// Produces something like:
  ///   bind<Type>().toProvide(() => method(args)).withName('name').singleton();
  /// Indent parameter allows formatted multiline output.
  ///
  /// RUSSIAN
  /// Формирует dart-код для биндинга, например:
  ///   bind<Type>().toProvide(() => method(args)).withName('name').singleton();
  /// Параметр [indent] задаёт отступ для красивого форматирования кода.
  /// -------------------------------------------------------------------------
  String generateBind(int indent) {
    final indentStr = ' ' * indent;
    final provide = _generateProvideClause(indent);
    final postfix = _generatePostfix();
    
    // Create the full single-line version first
    final singleLine = '${indentStr}bind<$returnType>()$provide$postfix;';
    
    // Check if we need multiline formatting
    final needsMultiline = singleLine.length > 80 || provide.contains('\n');
    
    if (!needsMultiline) {
      return singleLine;
    }
    
    // For multiline formatting, check if we need to break after bind<Type>()
    if (provide.contains('\n')) {
      // Provider clause is already multiline
      if (postfix.isNotEmpty) {
        // If there's a postfix, break after bind<Type>()
        final multilinePostfix = _generateMultilinePostfix(indent);
        return '${indentStr}bind<$returnType>()'  
               '\n${' ' * (indent + 4)}$provide'
               '$multilinePostfix;';
      } else {
        // No postfix, keep bind<Type>() with provide start
        return '${indentStr}bind<$returnType>()$provide;';
      }
    } else {
      // Simple multiline: break after bind<Type>()
      if (postfix.isNotEmpty) {
        final multilinePostfix = _generateMultilinePostfix(indent);
        return '${indentStr}bind<$returnType>()'  
               '\n${' ' * (indent + 4)}$provide'
               '$multilinePostfix;';
      } else {
        return '${indentStr}bind<$returnType>()'  
               '\n${' ' * (indent + 4)}$provide;';
      }
    }
  }

  // Internal method: decides how the provide clause should be generated by param kind.
  String _generateProvideClause(int indent) {
    if (hasParams) return _generateWithParamsProvideClause(indent);
    return _generatePlainProvideClause(indent);
  }

  /// EN / RU: Supports runtime parameters (@params).
  String _generateWithParamsProvideClause(int indent) {
    // Safe variable name for parameters.
    const paramVar = 'args';
    final fnArgs = parameters.map((p) => p.generateArg(paramVar)).join(', ');
    // Use multiline format only if args are long or contain newlines
    final multiLine = fnArgs.length > 60 || fnArgs.contains('\n');
    switch (bindingType) {
      case BindingType.instance:
        throw StateError(
            'Internal error: _generateWithParamsProvideClause called for @instance binding with @params.');
      //return isAsyncInstance
      //    ? '.toInstanceAsync(($fnArgs) => $methodName($fnArgs))'
      //    : '.toInstance(($fnArgs) => $methodName($fnArgs))';
      case BindingType.provide:
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

  /// EN / RU: Supports only injected dependencies, not runtime (@params).
  String _generatePlainProvideClause(int indent) {
    final argsStr = parameters.map((p) => p.generateArg()).join(', ');
    
    // Check if we need multiline formatting based on total line length
    final singleLineCall = '$methodName($argsStr)';
    final needsMultiline = singleLineCall.length >= 45 || argsStr.contains('\n');
    
    switch (bindingType) {
      case BindingType.instance:
        return isAsyncInstance
            ? '.toInstanceAsync($methodName($argsStr))'
            : '.toInstance($methodName($argsStr))';
      case BindingType.provide:
        if (isAsyncProvide) {
          if (needsMultiline) {
            final lambdaIndent = (isSingleton || named != null) ? indent + 6 : indent + 2;
            final closingIndent = (isSingleton || named != null) ? indent + 4 : indent;
            return '.toProvideAsync(\n${' ' * lambdaIndent}() => $methodName($argsStr),\n${' ' * closingIndent})';
          } else {
            return '.toProvideAsync(() => $methodName($argsStr))';
          }
        } else {
          if (needsMultiline) {
            final lambdaIndent = (isSingleton || named != null) ? indent + 6 : indent + 2;
            final closingIndent = (isSingleton || named != null) ? indent + 4 : indent;
            return '.toProvide(\n${' ' * lambdaIndent}() => $methodName($argsStr),\n${' ' * closingIndent})';
          } else {
            return '.toProvide(() => $methodName($argsStr))';
          }
        }
    }
  }

  /// EN / RU: Adds .withName and .singleton if needed.
  String _generatePostfix() {
    final namePart = named != null ? ".withName('$named')" : '';
    final singletonPart = isSingleton ? '.singleton()' : '';
    return '$namePart$singletonPart';
  }
  
  /// EN / RU: Generates multiline postfix with proper indentation.
  String _generateMultilinePostfix(int indent) {
    final parts = <String>[];
    if (named != null) {
      parts.add(".withName('$named')");
    }
    if (isSingleton) {
      parts.add('.singleton()');
    }
    if (parts.isEmpty) return '';
    
    return parts.map((part) => '\n${' ' * (indent + 4)}$part').join('');
  }

  /// -------------------------------------------------------------------------
  /// fromMethod
  ///
  /// ENGLISH
  /// Creates a BindSpec from a module class method by analyzing its return type,
  /// annotations, list of parameters (with their own annotations), and async-ness.
  /// Throws if a method does not have the required @instance() or @provide().
  ///
  /// RUSSIAN
  /// Создаёт спецификацию биндинга (BindSpec) из метода класса-модуля, анализируя
  /// возвращаемый тип, аннотации, параметры (и их аннотации), а также факт
  /// асинхронности. Если нет @instance или @provide — кидает ошибку.
  /// -------------------------------------------------------------------------
  static BindSpec fromMethod(MethodElement method) {
    try {
      // Validate method annotations
      AnnotationValidator.validateMethodAnnotations(method);
      
      // Parse return type using improved type parser
      final parsedReturnType = TypeParser.parseType(method.returnType, method);
      
      final methodName = method.displayName;
      
      // Check for @singleton annotation.
      final isSingleton = MetadataUtils.anyMeta(method.metadata, 'singleton');

      // Get @named value if present.
      final named = MetadataUtils.getNamedValue(method.metadata);

      // Parse each method parameter.
      final params = <BindParameterSpec>[];
      bool hasParams = false;
      for (final p in method.parameters) {
        final typeStr = p.type.getDisplayString();
        final paramNamed = MetadataUtils.getNamedValue(p.metadata);
        final isParams = MetadataUtils.anyMeta(p.metadata, 'params');
        if (isParams) hasParams = true;
        params.add(BindParameterSpec(typeStr, paramNamed, isParams: isParams));
      }

      // Determine bindingType: @instance or @provide.
      final hasInstance = MetadataUtils.anyMeta(method.metadata, 'instance');
      final hasProvide = MetadataUtils.anyMeta(method.metadata, 'provide');
      
      if (!hasInstance && !hasProvide) {
        throw AnnotationValidationException(
          'Method must be marked with either @instance() or @provide() annotation',
          element: method,
          suggestion: 'Add @instance() for direct instances or @provide() for factory methods',
          context: {
            'method_name': methodName,
            'return_type': parsedReturnType.displayString,
          },
        );
      }
      
      final bindingType = hasInstance ? BindingType.instance : BindingType.provide;

      // PROHIBIT @params with @instance bindings!
      if (bindingType == BindingType.instance && hasParams) {
        throw AnnotationValidationException(
          '@params() (runtime arguments) cannot be used together with @instance()',
          element: method,
          suggestion: 'Use @provide() instead if you want runtime arguments',
          context: {
            'method_name': methodName,
            'binding_type': 'instance',
            'has_params': hasParams,
          },
        );
      }

      // Set async flags based on parsed type
      final isAsyncInstance = bindingType == BindingType.instance && parsedReturnType.isFuture;
      final isAsyncProvide = bindingType == BindingType.provide && parsedReturnType.isFuture;

      return BindSpec(
        returnType: parsedReturnType.codeGenType,
        methodName: methodName,
        isSingleton: isSingleton,
        named: named,
        parameters: params,
        bindingType: bindingType,
        isAsyncInstance: isAsyncInstance,
        isAsyncProvide: isAsyncProvide,
        hasParams: hasParams,
      );
    } catch (e) {
      if (e is CherryPickGeneratorException) {
        rethrow;
      }
      throw CodeGenerationException(
        'Failed to create BindSpec from method "${method.displayName}"',
        element: method,
        suggestion: 'Check that the method has valid annotations and return type',
        context: {
          'method_name': method.displayName,
          'return_type': method.returnType.getDisplayString(),
          'error': e.toString(),
        },
      );
    }
  }
}
