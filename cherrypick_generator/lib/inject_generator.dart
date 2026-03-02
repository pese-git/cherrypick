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

import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';
import 'package:cherrypick_annotations/cherrypick_annotations.dart' as ann;

import 'src/annotation_validator.dart';
import 'src/code_builder_emitters.dart';
import 'src/type_parser.dart';

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
  dynamic generateForAnnotatedElement(
    Element2 element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement2) {
      throw InvalidGenerationSourceError(
        '@injectable() can only be applied to classes.',
        element: element,
      );
    }

    final classElement = element;
    final className = classElement.firstFragment.name2;
    final mixinName = '_\$$className';

    AnnotationValidator.validateClassAnnotations(classElement);

    final classType = TypeParser.parseType(
      classElement.thisType,
      classElement,
    );

    final injectFields = classElement.fields2
        .where((f) => _isInjectField(f))
        .map(_parseInjectField)
        .toList();

    final injectMethod = Method((b) {
      b
        ..name = '_inject'
        ..returns = refer('void')
        ..requiredParameters.add(
          Parameter((p) {
            p
              ..name = 'instance'
              ..type = CodeBuilderEmitters.resolveTypeRef(classType);
          }),
        )
        ..body = Block((body) {
          for (final field in injectFields) {
            final scopeExpr = CodeBuilderEmitters.openScope(
              scopeName: field.scopeName,
            );
            final resolveExpr = CodeBuilderEmitters.resolveCall(
              scopeExpr: scopeExpr,
              parsedType: field.parsedType,
              named: field.namedValue,
            );
            body.statements.add(
              refer('instance')
                  .property(field.fieldName)
                  .assign(resolveExpr)
                  .statement,
            );
          }
        });
    });

    final mixin = Mixin((b) {
      b
        ..name = mixinName
        ..methods.add(injectMethod);
    });

    final library = Library((b) => b..body.add(mixin));
    final emitter = DartEmitter(useNullSafetySyntax: true);
    return '${library.accept(emitter)}';
  }

  /// Returns true if a field is annotated with `@inject`.
  ///
  /// Used to detect which fields should be processed for injection.
  static bool _isInjectField(FieldElement2 field) {
    return field.firstFragment.metadata2.annotations.any(
      (m) => m.computeConstantValue()?.type?.getDisplayString() == 'inject',
    );
  }

  /// Parses `@inject()` field and extracts all injection metadata
  /// (core type, qualifiers, scope, nullability, etc).
  ///
  /// Converts Dart field declaration and all parameterizing injection-related
  /// annotations into a [_ParsedInjectField] which is used for codegen.
  static _ParsedInjectField _parseInjectField(FieldElement2 field) {
    AnnotationValidator.validateFieldAnnotations(field);

    String? scopeName;
    String? namedValue;

    for (final meta in field.firstFragment.metadata2.annotations) {
      final obj = meta.computeConstantValue();
      final type = obj?.type?.getDisplayString();
      if (type == 'scope') {
        scopeName = obj?.getField('name')?.toStringValue();
      } else if (type == 'named') {
        namedValue = obj?.getField('value')?.toStringValue();
      }
    }

    final DartType dartType = field.type;
    final parsedType = TypeParser.parseType(dartType, field);

    return _ParsedInjectField(
      fieldName: field.firstFragment.name2 ?? '',
      parsedType: parsedType,
      scopeName: scopeName,
      namedValue: namedValue,
    );
  }
}

/// Internal structure: describes all required information for generating the injection
/// assignment for a given field.
///
/// Not exported. Used as a DTO in the generator for each field.
class _ParsedInjectField {
  /// The name of the field to be injected.
  final String fieldName;

  /// Parsed type info for the field.
  final ParsedType parsedType;

  /// The scoping for DI resolution, or null to use root scope.
  final String? scopeName;

  /// Name qualifier for named resolution, or null if not set.
  final String? namedValue;

  _ParsedInjectField({
    required this.fieldName,
    required this.parsedType,
    this.scopeName,
    this.namedValue,
  });
}

/// Factory for creating the build_runner builder for DI field injection.
///
/// Add this builder in your build.yaml if you're invoking CherryPick generators manually.
Builder injectBuilder(BuilderOptions options) =>
    PartBuilder([InjectGenerator()], '.inject.cherrypick.g.dart');
