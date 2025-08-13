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

import 'dart:async';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:cherrypick_annotations/cherrypick_annotations.dart' as ann;

/// CherryPick DI field injector generator for codegen.
///
/// Analyzes all Dart classes marked with `@injectable()` and generates a mixin (for example, `_$ProfileScreen`)
/// which contains the `_inject` method. This method will assign all fields annotated with `@inject()`
/// using the CherryPick DI container. Extra annotation qualifiers such as `@named` and `@scope` are respected
/// for each field. Nullable fields and Future/injectable async dependencies are also supported automatically.
///
/// ---
///
/// ### Example usage in a project:
///
/// ```dart
/// import 'package:cherrypick_annotations/cherrypick_annotations.dart';
///
/// @injectable()
/// class MyScreen with _$MyScreen {
///   @inject()
///   late final Logger logger;
///
///   @inject()
///   @named('test')
///   late final HttpClient client;
///
///   @inject()
///   Future<Analytics>? analytics;
/// }
/// ```
///
/// After running build_runner, this mixin will be auto-generated:
///
/// ```dart
/// mixin _$MyScreen {
///   void _inject(MyScreen instance) {
///     instance.logger = CherryPick.openRootScope().resolve<Logger>();
///     instance.client = CherryPick.openRootScope().resolve<HttpClient>(named: 'test');
///     instance.analytics = CherryPick.openRootScope().tryResolveAsync<Analytics>(); // nullable async inject
///   }
/// }
/// ```
///
/// You may use the mixin (e.g., `myScreen._inject(myScreen)`) or expose your own public helper for instance field injection.
///
/// **Supported scenarios:**
/// - Ordinary injectable fields: `resolve<T>()`.
/// - Named qualifiers: `resolve<T>(named: ...)`.
/// - Scoping: `CherryPick.openScope(scopeName: ...).resolve<T>()`.
/// - Nullable/incomplete fields: `tryResolve`/`tryResolveAsync`.
/// - Async dependencies: `Future<T>`/`resolveAsync<T>()`.
///
/// See also:
///   * @inject
///   * @injectable
class InjectGenerator extends GeneratorForAnnotation<ann.injectable> {
  const InjectGenerator();

  /// Main entry point for CherryPick field injection code generation.
  ///
  /// - Only triggers for classes marked with `@injectable()`.
  /// - Throws an error if used on non-class elements.
  /// - Scans all fields marked with `@inject()` and gathers qualifiers (if any).
  /// - Generates Dart code for a mixin that injects all dependencies into the target class instance.
  ///
  /// Returns the Dart code as a String defining the new mixin.
  ///
  /// Example input (user code):
  /// ```dart
  /// @injectable()
  /// class UserBloc with _$UserBloc {
  ///   @inject() late final AuthRepository authRepository;
  /// }
  /// ```
  /// Example output (generated):
  /// ```dart
  /// mixin _$UserBloc {
  ///   void _inject(UserBloc instance) {
  ///     instance.authRepository = CherryPick.openRootScope().resolve<AuthRepository>();
  ///   }
  /// }
  /// ```
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@injectable() can only be applied to classes.',
        element: element,
      );
    }

    final classElement = element;
    final className = classElement.name;
    final mixinName = '_\$$className';

    final buffer = StringBuffer()
      ..writeln('mixin $mixinName {')
      ..writeln('  void _inject($className instance) {');

    // Collect and process all @inject fields
    final injectFields =
        classElement.fields.where(_isInjectField).map(_parseInjectField);

    for (final parsedField in injectFields) {
      buffer.writeln(_generateInjectionLine(parsedField));
    }

    buffer
      ..writeln('  }')
      ..writeln('}');

    return buffer.toString();
  }

  /// Returns true if a field is annotated with `@inject`.
  ///
  /// Used to detect which fields should be processed for injection.
  static bool _isInjectField(FieldElement field) {
    return field.metadata.any(
      (m) => m.computeConstantValue()?.type?.getDisplayString() == 'inject',
    );
  }

  /// Parses `@inject()` field and extracts all injection metadata
  /// (core type, qualifiers, scope, nullability, etc).
  ///
  /// Converts Dart field declaration and all parameterizing injection-related
  /// annotations into a [_ParsedInjectField] which is used for codegen.
  static _ParsedInjectField _parseInjectField(FieldElement field) {
    String? scopeName;
    String? namedValue;

    for (final meta in field.metadata) {
      final DartObject? obj = meta.computeConstantValue();
      final type = obj?.type?.getDisplayString();
      if (type == 'scope') {
        scopeName = obj?.getField('name')?.toStringValue();
      } else if (type == 'named') {
        namedValue = obj?.getField('value')?.toStringValue();
      }
    }

    final DartType dartType = field.type;
    String coreTypeName;
    bool isFuture;

    if (dartType.isDartAsyncFuture) {
      final ParameterizedType paramType = dartType as ParameterizedType;
      coreTypeName = paramType.typeArguments.first.getDisplayString();
      isFuture = true;
    } else {
      coreTypeName = dartType.getDisplayString();
      isFuture = false;
    }

    // Determine nullability for field types like T? or Future<T?>
    bool isNullable = dartType.nullabilitySuffix ==
            NullabilitySuffix.question ||
        (dartType is ParameterizedType &&
            (dartType)
                .typeArguments
                .any((t) => t.nullabilitySuffix == NullabilitySuffix.question));

    return _ParsedInjectField(
      fieldName: field.name,
      coreType: coreTypeName.replaceAll('?', ''), // удаляем "?" на всякий
      isFuture: isFuture,
      isNullable: isNullable,
      scopeName: scopeName,
      namedValue: namedValue,
    );
  }

  /// Generates Dart code for a single dependency-injected field based on its metadata.
  ///
  /// This code will resolve the field from the CherryPick DI container and assign it to the class instance.
  /// Correctly dispatches to resolve, tryResolve, resolveAsync, or tryResolveAsync methods,
  /// and applies container scoping or named resolution where required.
  ///
  /// Returns literal Dart code as string (1 line).
  ///
  /// Example output:
  ///   `instance.logger = CherryPick.openRootScope().resolve<Logger>();`
  String _generateInjectionLine(_ParsedInjectField field) {
    final resolveMethod = field.isFuture
        ? (field.isNullable
            ? 'tryResolveAsync<${field.coreType}>'
            : 'resolveAsync<${field.coreType}>')
        : (field.isNullable
            ? 'tryResolve<${field.coreType}>'
            : 'resolve<${field.coreType}>');

    final openCall = (field.scopeName != null && field.scopeName!.isNotEmpty)
        ? "CherryPick.openScope(scopeName: '${field.scopeName}')"
        : "CherryPick.openRootScope()";

    final params = (field.namedValue != null && field.namedValue!.isNotEmpty)
        ? "(named: '${field.namedValue}')"
        : '()';

    return "    instance.${field.fieldName} = $openCall.$resolveMethod$params;";
  }
}

/// Internal structure: describes all required information for generating the injection
/// assignment for a given field.
///
/// Not exported. Used as a DTO in the generator for each field.
class _ParsedInjectField {
  /// The name of the field to be injected.
  final String fieldName;

  /// The Dart type to resolve (e.g. `Logger` from `Logger` or `Future<Logger>`).
  final String coreType;

  /// True if the field is an async dependency (Future<...>), otherwise false.
  final bool isFuture;

  /// True if the field accepts null (T?), otherwise false.
  final bool isNullable;

  /// The scoping for DI resolution, or null to use root scope.
  final String? scopeName;

  /// Name qualifier for named resolution, or null if not set.
  final String? namedValue;

  _ParsedInjectField({
    required this.fieldName,
    required this.coreType,
    required this.isFuture,
    required this.isNullable,
    this.scopeName,
    this.namedValue,
  });
}

/// Factory for creating the build_runner builder for DI field injection.
///
/// Add this builder in your build.yaml if you're invoking CherryPick generators manually.
Builder injectBuilder(BuilderOptions options) =>
    PartBuilder([InjectGenerator()], '.inject.cherrypick.g.dart');
