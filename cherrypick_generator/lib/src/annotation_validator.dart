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
import 'exceptions.dart';
import 'metadata_utils.dart';

/// Validates annotation combinations and usage patterns
class AnnotationValidator {
  /// Validates annotations on a method element
  static void validateMethodAnnotations(MethodElement method) {
    final annotations = _getAnnotationNames(method.metadata);

    _validateMutuallyExclusiveAnnotations(method, annotations);
    _validateAnnotationCombinations(method, annotations);
    _validateAnnotationParameters(method);
  }

  /// Validates annotations on a field element
  static void validateFieldAnnotations(FieldElement field) {
    final annotations = _getAnnotationNames(field.metadata);

    _validateInjectFieldAnnotations(field, annotations);
  }

  /// Validates annotations on a class element
  static void validateClassAnnotations(ClassElement classElement) {
    final annotations = _getAnnotationNames(classElement.metadata);

    _validateModuleClassAnnotations(classElement, annotations);
    _validateInjectableClassAnnotations(classElement, annotations);
  }

  static List<String> _getAnnotationNames(List<ElementAnnotation> metadata) {
    return metadata
        .map((m) => m.computeConstantValue()?.type?.getDisplayString())
        .where((name) => name != null)
        .cast<String>()
        .toList();
  }

  static void _validateMutuallyExclusiveAnnotations(
    MethodElement method,
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

  static void _validateAnnotationCombinations(
    MethodElement method,
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

  static void _validateSingletonUsage(
    MethodElement method,
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
        context: {
          'method_name': method.displayName,
          'return_type': returnType,
        },
      );
    }
  }

  static void _validateAnnotationParameters(MethodElement method) {
    // Validate @named annotation parameters
    final namedValue = MetadataUtils.getNamedValue(method.metadata);
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
    for (final param in method.parameters) {
      final paramAnnotations = _getAnnotationNames(param.metadata);
      if (paramAnnotations.contains('params')) {
        _validateParamsParameter(param, method);
      }
    }
  }

  static void _validateParamsParameter(
      ParameterElement param, MethodElement method) {
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

  static void _validateInjectFieldAnnotations(
    FieldElement field,
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
        context: {
          'field_name': field.displayName,
          'field_type': fieldType,
        },
      );
    }

    // Validate scope annotation if present
    for (final meta in field.metadata) {
      final obj = meta.computeConstantValue();
      final type = obj?.type?.getDisplayString();
      if (type == 'scope') {
        // Empty scope name is treated as no scope (uses root scope)
        // This is allowed for backward compatibility and convenience
      }
    }
  }

  static void _validateModuleClassAnnotations(
    ClassElement classElement,
    List<String> annotations,
  ) {
    if (!annotations.contains('module')) {
      return; // Not a module class
    }

    // Check if class has public methods
    final publicMethods =
        classElement.methods.where((m) => m.isPublic).toList();
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
      final methodAnnotations = _getAnnotationNames(method.metadata);
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

  static void _validateInjectableClassAnnotations(
    ClassElement classElement,
    List<String> annotations,
  ) {
    if (!annotations.contains('injectable')) {
      return; // Not an injectable class
    }

    // Check if class has injectable fields
    final injectFields = classElement.fields.where((f) {
      final fieldAnnotations = _getAnnotationNames(f.metadata);
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
