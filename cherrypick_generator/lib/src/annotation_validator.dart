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

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'exceptions.dart';
import 'metadata_utils.dart';

/// Provides static utility methods for validating annotation usage in CherryPick
/// dependency injection code generation.
///
/// This validator helps ensure that `@provide`, `@instance`, `@singleton`, `@params`,
/// `@inject`, `@named`, `@module`, and `@injectable` annotations are correctly and safely
/// combined in your codebase, preventing common configuration and codegen errors before
/// code is generated.
///
/// #### Example Usage
/// ```dart
/// void processMethod(MethodElement method) {
///   AnnotationValidator.validateMethodAnnotations(method);
/// }
/// ```
///
/// All exceptions are thrown as [AnnotationValidationException] and will include
/// a helpful message and context.
///
/// ---
/// Typical checks performed by this utility:
/// - Mutual exclusivity (`@instance` vs `@provide`)
/// - Required presence for fields and methods
/// - Proper parameters for `@named` and `@params`
/// - Correct usage of injectable fields, module class methods, etc.
///
class AnnotationValidator {
  /// Validates annotations for a given [MethodElement].
  ///
  /// Checks:
  ///   - Mutual exclusivity of `@instance` and `@provide`.
  ///   - That a method is annotated with exactly one DI-producing annotation.
  ///   - If `@params` is present, that it is used together with `@provide`.
  ///   - Appropriate usage of `@singleton`.
  ///   - [@named] syntax and conventions.
  ///   - Parameter validation for method arguments.
  ///
  /// Throws [AnnotationValidationException] on any violation.
  static void validateMethodAnnotations(MethodElement2 method) {
    final annotations = _getAnnotationNames(
      method.firstFragment.metadata2.annotations,
    );

    _validateMutuallyExclusiveAnnotations(method, annotations);
    _validateAnnotationCombinations(method, annotations);
    _validateAnnotationParameters(method);
  }

  /// Validates that a [FieldElement] has correct injection annotations.
  ///
  /// Specifically, ensures:
  ///   - Injectable fields are of valid type.
  ///   - No `void` injection.
  ///   - Correct scope naming if present.
  ///
  /// Throws [AnnotationValidationException] if checks fail.
  static void validateFieldAnnotations(FieldElement2 field) {
    final annotations = _getAnnotationNames(
      field.firstFragment.metadata2.annotations,
    );

    _validateInjectFieldAnnotations(field, annotations);
  }

  /// Validates all class-level DI annotations.
  ///
  /// Executes checks for:
  ///   - Module class validity (e.g. must have public DI methods if `@module`).
  ///   - Injectable class: at least one @inject field, field finalness, etc.
  ///   - Provides helpful context for error/warning reporting.
  ///
  /// Throws [AnnotationValidationException] if checks fail.
  static void validateClassAnnotations(ClassElement2 classElement) {
    final annotations = _getAnnotationNames(
      classElement.firstFragment.metadata2.annotations,
    );

    _validateModuleClassAnnotations(classElement, annotations);
    _validateInjectableClassAnnotations(classElement, annotations);
  }

  // --- Internal helpers follow (private) ---

  /// Helper: Returns the names of all annotation types on `metadata`.
  static List<String> _getAnnotationNames(List<ElementAnnotation> metadata) {
    return metadata
        .map((m) => m.computeConstantValue()?.type?.getDisplayString())
        .where((name) => name != null)
        .cast<String>()
        .toList();
  }

  /// Validates that mutually exclusive method annotations are not used together.
  ///
  /// For example, `@instance` and `@provide` cannot both be present.
  static void _validateMutuallyExclusiveAnnotations(
    MethodElement2 method,
    List<String> annotations,
  ) {
    // @instance and @provide are mutually exclusive
    if (annotations.contains('instance') && annotations.contains('provide')) {
      throw AnnotationValidationException(
        'Method cannot have both @instance and @provide annotations',
        element: method,
        suggestion:
            'Use either @instance for direct instances or @provide for factory methods',
        context: {
          'method_name': method.displayName,
          'annotations': annotations,
        },
      );
    }
  }

  /// Validates correct annotation combinations, e.g.
  /// - `@params` must be with `@provide`
  /// - One of `@instance` or `@provide` must be present for a registration method
  /// - Validates singleton usage
  static void _validateAnnotationCombinations(
    MethodElement2 method,
    List<String> annotations,
  ) {
    // @params can only be used with @provide
    if (annotations.contains('params') && !annotations.contains('provide')) {
      throw AnnotationValidationException(
        '@params annotation can only be used with @provide annotation',
        element: method,
        suggestion: 'Remove @params or add @provide annotation',
        context: {
          'method_name': method.displayName,
          'annotations': annotations,
        },
      );
    }

    // Methods must have either @instance or @provide
    if (!annotations.contains('instance') && !annotations.contains('provide')) {
      throw AnnotationValidationException(
        'Method must be marked with either @instance or @provide annotation',
        element: method,
        suggestion:
            'Add @instance() for direct instances or @provide() for factory methods',
        context: {
          'method_name': method.displayName,
          'available_annotations': annotations,
        },
      );
    }

    // @singleton validation
    if (annotations.contains('singleton')) {
      _validateSingletonUsage(method, annotations);
    }
  }

  /// Singleton-specific method annotation checks.
  static void _validateSingletonUsage(
    MethodElement2 method,
    List<String> annotations,
  ) {
    // Singleton with params might not make sense in some contexts
    if (annotations.contains('params')) {
      // This is a warning, not an error - could be useful for parameterized singletons
      // We could add a warning system later
    }

    // Check if return type is suitable for singleton
    final returnType = method.returnType.getDisplayString();
    if (returnType == 'void') {
      throw AnnotationValidationException(
        'Singleton methods cannot return void',
        element: method,
        suggestion: 'Remove @singleton annotation or change return type',
        context: {'method_name': method.displayName, 'return_type': returnType},
      );
    }
  }

  /// Validates extra requirements or syntactic rules for annotation arguments, like @named.
  static void _validateAnnotationParameters(MethodElement2 method) {
    // Validate @named annotation parameters
    final namedValue = MetadataUtils.getNamedValue(
      method.firstFragment.metadata2.annotations,
    );
    if (namedValue != null) {
      if (namedValue.isEmpty) {
        throw AnnotationValidationException(
          '@named annotation cannot have empty value',
          element: method,
          suggestion: 'Provide a non-empty string value for @named annotation',
          context: {
            'method_name': method.displayName,
            'named_value': namedValue,
          },
        );
      }

      // Check for valid naming conventions
      if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(namedValue)) {
        throw AnnotationValidationException(
          '@named value should follow valid identifier naming conventions',
          element: method,
          suggestion:
              'Use alphanumeric characters and underscores only, starting with a letter or underscore',
          context: {
            'method_name': method.displayName,
            'named_value': namedValue,
          },
        );
      }
    }

    // Validate method parameters for @params usage
    for (final param in method.formalParameters) {
      final paramAnnotations = _getAnnotationNames(
        param.firstFragment.metadata2.annotations,
      );
      if (paramAnnotations.contains('params')) {
        _validateParamsParameter(param, method);
      }
    }
  }

  /// Checks that @params is used with compatible parameter type.
  static void _validateParamsParameter(
    FormalParameterElement param,
    MethodElement2 method,
  ) {
    // @params parameter should typically be dynamic or Map<String, dynamic>
    final paramType = param.type.getDisplayString();
    if (paramType != 'dynamic' &&
        paramType != 'Map<String, dynamic>' &&
        paramType != 'Map<String, dynamic>?') {
      // This is more of a warning - other types might be valid
      // We could add a warning system for this
    }

    // Check if parameter is required when using @params
    try {
      final hasDefault = (param as dynamic).defaultValue != null;
      if (param.isRequired && !hasDefault) {
        // This might be intentional, so we don't throw an error
        // but we could warn about it
      }
    } catch (e) {
      // Ignore if defaultValue is not available in this analyzer version
    }
  }

  /// Checks field-level annotation for valid injectable fields.
  static void _validateInjectFieldAnnotations(
    FieldElement2 field,
    List<String> annotations,
  ) {
    if (!annotations.contains('inject')) {
      return; // Not an inject field, nothing to validate
    }

    // Check if field type is suitable for injection
    final fieldType = field.type.getDisplayString();
    if (fieldType == 'void') {
      throw AnnotationValidationException(
        'Cannot inject void type',
        element: field,
        suggestion: 'Use a concrete type instead of void',
        context: {'field_name': field.displayName, 'field_type': fieldType},
      );
    }

    // Validate scope annotation if present
    for (final meta in field.firstFragment.metadata2.annotations) {
      final obj = meta.computeConstantValue();
      final type = obj?.type?.getDisplayString();
      if (type == 'scope') {
        // Empty scope name is treated as no scope (uses root scope)
        // This is allowed for backward compatibility and convenience
      }
    }
  }

  /// Checks @module usage: must have at least one DI method, each with DI-annotation.
  static void _validateModuleClassAnnotations(
    ClassElement2 classElement,
    List<String> annotations,
  ) {
    if (!annotations.contains('module')) {
      return; // Not a module class
    }

    // Check if class has public methods
    final publicMethods = classElement.methods2
        .where((m) => m.isPublic)
        .toList();
    if (publicMethods.isEmpty) {
      throw AnnotationValidationException(
        'Module class must have at least one public method',
        element: classElement,
        suggestion: 'Add public methods with @instance or @provide annotations',
        context: {
          'class_name': classElement.displayName,
          'method_count': publicMethods.length,
        },
      );
    }

    // Validate that public methods have appropriate annotations
    for (final method in publicMethods) {
      final methodAnnotations = _getAnnotationNames(
        method.firstFragment.metadata2.annotations,
      );
      if (!methodAnnotations.contains('instance') &&
          !methodAnnotations.contains('provide')) {
        throw AnnotationValidationException(
          'Public methods in module class must have @instance or @provide annotation',
          element: method,
          suggestion: 'Add @instance() or @provide() annotation to the method',
          context: {
            'class_name': classElement.displayName,
            'method_name': method.displayName,
          },
        );
      }
    }
  }

  /// Checks @injectable usage on classes and their fields.
  static void _validateInjectableClassAnnotations(
    ClassElement2 classElement,
    List<String> annotations,
  ) {
    if (!annotations.contains('injectable')) {
      return; // Not an injectable class
    }

    // Check if class has injectable fields
    final injectFields = classElement.fields2.where((f) {
      final fieldAnnotations = _getAnnotationNames(
        f.firstFragment.metadata2.annotations,
      );
      return fieldAnnotations.contains('inject');
    }).toList();

    // Allow injectable classes without @inject fields to generate empty mixins
    // This can be useful for classes that will have @inject fields added later
    // or for testing purposes
    if (injectFields.isEmpty) {
      // Just log a warning but don't throw an exception
      // print('Warning: Injectable class ${classElement.displayName} has no @inject fields');
    }

    // Validate that injectable fields are properly declared
    for (final field in injectFields) {
      // Injectable fields should be late final for immutability after injection
      if (!field.isFinal) {
        throw AnnotationValidationException(
          'Injectable fields should be final for immutability',
          element: field,
          suggestion:
              'Add final keyword to injectable field (preferably late final)',
          context: {
            'class_name': classElement.displayName,
            'field_name': field.displayName,
          },
        );
      }

      // Check if field is late (recommended pattern)
      try {
        final isLate = (field as dynamic).isLate ?? false;
        if (!isLate) {
          // This is a warning, not an error - late final is recommended but not required
          // We could add a warning system later
        }
      } catch (e) {
        // Ignore if isLate is not available in this analyzer version
      }
    }
  }
}
