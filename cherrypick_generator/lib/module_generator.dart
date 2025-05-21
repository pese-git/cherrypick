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
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:cherrypick_annotations/cherrypick_annotations.dart' as ann;

///
/// Генератор зависимостей для DI-контейнера на основе аннотаций.
///
/// Данный генератор автоматически создаёт код для внедрения зависимостей (DI)
/// на основе аннотаций в вашем исходном коде. Когда вы отмечаете класс
/// аннотацией `@module()`, этот генератор обработает все его публичные методы
/// и автоматически сгенерирует класс с биндингами (регистрациями зависимостей)
/// для DI-контейнера. Это избавляет от написания однообразного шаблонного кода.
///
class ModuleGenerator extends GeneratorForAnnotation<ann.module> {
  /// Генерирует исходный код для класса-модуля с аннотацией `@module()`.
  ///
  /// [element] — исходный класс, помеченный аннотацией.
  /// [annotation] — значения параметров аннотации.
  /// [buildStep] — информация о текущем шаге генерации.
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    // Генератор обрабатывает только классы (остальное — ошибка)
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@module() может быть применён только к классам.',
        element: element,
      );
    }

    final classElement = element;

    // Создаёт объект, описывающий, какие биндинги нужно сгенерировать на основании методов класса
    final generatedClass = _GeneratedClass.fromClassElement(classElement);

    // Генерирует итоговый Dart-код
    return generatedClass.generate();
  }
}

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
    if (hasParams) {
      // Параметры метода: все, кроме isParams --> resolve(...)
      //                    последний isParams --> "params"
      final paramsArgs = parameters.map((p) => p.generateArg()).join(', ');

      String provide;
      if (bindingType == 'instance') {
        // По умолчанию instance с @params, делать нельзя — но если нужно, аналогично provide.
        provide = isAsyncInstance
            ? '.toInstanceAsync(($paramsArgs) => $methodName($paramsArgs))'
            : '.toInstance(($paramsArgs) => $methodName($paramsArgs))';
      } else {
        final fnArgs = parameters
            .map((p) => p.isParams ? 'params' : p.generateArg())
            .join(', ');
        if (isAsyncProvide) {
          provide = (fnArgs.length > 60 || fnArgs.contains('\n'))
              ? '.toProvideAsyncWithParams(\n${' ' * (indent + 2)}(params) => $methodName($fnArgs))'
              : '.toProvideAsyncWithParams((params) => $methodName($fnArgs))';
        } else {
          provide = (fnArgs.length > 60 || fnArgs.contains('\n'))
              ? '.toProvideWithParams(\n${' ' * (indent + 2)}(params) => $methodName($fnArgs))'
              : '.toProvideWithParams((params) => $methodName($fnArgs))';
        }
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
    final isSingleton = _MetadataUtils.anyMeta(method.metadata, 'singleton');

    // Получаем имя из @named(), если есть
    final named = _MetadataUtils.getNamedValue(method.metadata);

    // Для каждого параметра метода
    final params = <BindParameterSpec>[];
    bool hasParams = false;
    for (final p in method.parameters) {
      final typeStr = p.type.getDisplayString();
      final paramNamed = _MetadataUtils.getNamedValue(p.metadata);
      final isParams = _MetadataUtils.anyMeta(p.metadata, 'params');
      if (isParams) hasParams = true;
      params.add(BindParameterSpec(typeStr, paramNamed, isParams: isParams));
    }

    // определяем bindingType
    final hasInstance = _MetadataUtils.anyMeta(method.metadata, 'instance');
    final hasProvide = _MetadataUtils.anyMeta(method.metadata, 'provide');
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
  String generateArg([String paramsVar = 'params']) {
    if (isParams) {
      return paramsVar;
    }
    if (named != null) {
      return "currentScope.resolve<$typeName>(named: '$named')";
    }
    return "currentScope.resolve<$typeName>()";
  }
}

///
/// Результат обработки одного класса-модуля: имя класса, его биндинги,
/// имя генерируемого класса и т.д.
///
class _GeneratedClass {
  /// Имя исходного класса-модуля
  final String className;

  /// Имя генерируемого класса (например, $SomeModule)
  final String generatedClassName;

  /// Список всех обнаруженных биндингов
  final List<BindSpec> binds;

  _GeneratedClass(
    this.className,
    this.generatedClassName,
    this.binds,
  );

  /// Обрабатывает объект ClassElement (отображение класса в AST)
  /// и строит структуру _GeneratedClass для генерации кода.
  static _GeneratedClass fromClassElement(ClassElement element) {
    final className = element.displayName;
    // Имя с префиксом $ (стандартная практика для ген-кода)
    final generatedClassName = r'$' + className;
    // Собираем биндинги по всем методам класса, игнорируем абстрактные (без реализации)
    final binds = element.methods
        .where((m) => !m.isAbstract)
        .map(BindSpec.fromMethod)
        .toList();

    return _GeneratedClass(className, generatedClassName, binds);
  }

  /// Генерирует исходный Dart-код для созданного класса DI-модуля.
  ///
  /// Внутри builder(Scope currentScope) регистрируются все bind-методы.
  String generate() {
    final buffer = StringBuffer();

    buffer.writeln('final class $generatedClassName extends $className {');
    buffer.writeln(' @override');
    buffer.writeln(' void builder(Scope currentScope) {');

    // Для каждого биндинга — генерируем строку bind<Type>()...
    for (final bind in binds) {
      buffer.writeln(bind.generateBind(4));
    }

    buffer.writeln(' }');
    buffer.writeln('}');

    return buffer.toString();
  }
}

///
/// Утилиты для разбора аннотаций методов и параметров.
/// Позволяют найти @named() и @singleton() у метода/параметра.
///
class _MetadataUtils {
  /// Проверяет: есть ли среди аннотаций метка, имя которой содержит [typeName]
  /// (регистр не учитывается)
  static bool anyMeta(List<ElementAnnotation> meta, String typeName) {
    return meta.any((m) =>
        m
            .computeConstantValue()
            ?.type
            ?.getDisplayString()
            .toLowerCase()
            .contains(typeName.toLowerCase()) ??
        false);
  }

  /// Находит значение из аннотации @named('значение').
  /// Возвращает строку значения, если аннотация присутствует; иначе null.
  static String? getNamedValue(List<ElementAnnotation> meta) {
    for (final m in meta) {
      final cv = m.computeConstantValue();

      final typeStr = cv?.type?.getDisplayString().toLowerCase();

      if (typeStr?.contains('named') ?? false) {
        return cv?.getField('value')?.toStringValue();
      }
    }

    return null;
  }
}

///
/// Точка входа для генератора build_runner.
/// Возвращает Builder, используемый build_runner для генерации кода для всех
/// файлов, где встречается @module().
///
Builder moduleBuilder(BuilderOptions options) =>
    PartBuilder([ModuleGenerator()], '.cherrypick.g.dart');
