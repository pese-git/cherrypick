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
import 'package:source_gen/source_gen.dart';

/// ---------------------------------------------------------------------------
/// CherryPickGeneratorException
///
/// The base exception for all CherryPick code generation and annotation
/// validation errors. This exception provides enhanced diagnostics including
/// the error category, helpful suggestions, and additional debugging context.
///
/// All errors are structured to be as helpful as possible for users
/// running build_runner and for CherryPick contributors debugging generators.
///
/// ## Example usage:
/// ```dart
/// if (someErrorCondition) {
///   throw AnnotationValidationException(
///     'Custom message about what went wrong',
///     element: methodElement,
///     suggestion: 'Add @provide() or @instance() annotation',
///     context: {'found_annotations': annotations},
///   );
/// }
/// ```
/// ---------------------------------------------------------------------------
class CherryPickGeneratorException extends InvalidGenerationSourceError {
  /// A string describing the error category (for grouping).
  final String category;

  /// An optional suggestion string for resolving the error.
  final String? suggestion;

  /// Arbitrary key-value map for additional debugging information.
  final Map<String, dynamic>? context;

  CherryPickGeneratorException(
    String message, {
    required Element2 element,
    required this.category,
    this.suggestion,
    this.context,
  }) : super(
          _formatMessage(message, category, suggestion, context, element),
          element: element,
        );

  static String _formatMessage(
    String message,
    String category,
    String? suggestion,
    Map<String, dynamic>? context,
    Element2 element,
  ) {
    final buffer = StringBuffer();

    // Header with category
    buffer.writeln('[$category] $message');

    // Element context
    buffer.writeln('');
    buffer.writeln('Context:');
    buffer.writeln('  Element: ${element.displayName}');
    buffer.writeln('  Type: ${element.runtimeType}');
    buffer.writeln(
      '  Location: ${element.firstFragment.libraryFragment?.source.fullName ?? 'unknown'}',
    );

    // Try to show enclosing element info for extra context
    try {
      final enclosing = (element as dynamic).enclosingElement;
      if (enclosing != null) {
        buffer.writeln('  Enclosing: ${enclosing.displayName}');
      }
    } catch (e) {
      // Ignore if enclosingElement is not available
    }

    // Arbitrary user context
    if (context != null && context.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Additional Context:');
      context.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }

    // Hint/suggestion if present
    if (suggestion != null) {
      buffer.writeln('');
      buffer.writeln('💡 Suggestion: $suggestion');
    }

    return buffer.toString();
  }
}

/// ---------------------------------------------------------------------------
/// AnnotationValidationException
///
/// Thrown when annotation usage is invalid (e.g., missing required annotation,
/// mutually exclusive annotations, or incorrect @named format).
///
/// Grouped as category "ANNOTATION_VALIDATION".
///
/// ## Example:
/// ```dart
/// throw AnnotationValidationException(
///   '@instance and @provide cannot be used together',
///   element: method,
///   suggestion: 'Use only one of @instance or @provide.',
///   context: {'method_name': method.displayName},
/// );
/// ```
/// ---------------------------------------------------------------------------
class AnnotationValidationException extends CherryPickGeneratorException {
  AnnotationValidationException(
    super.message, {
    required super.element,
    super.suggestion,
    super.context,
  }) : super(category: 'ANNOTATION_VALIDATION');
}

/// ---------------------------------------------------------------------------
/// TypeParsingException
///
/// Thrown when a Dart type cannot be interpreted/parsed for DI,
/// or if it's not compatible (void, raw Future, etc).
///
/// Grouped as category "TYPE_PARSING".
///
/// ## Example:
/// ```dart
/// throw TypeParsingException(
///   'Cannot parse injected type',
///   element: field,
///   suggestion: 'Specify a concrete type. Avoid dynamic and raw Future.',
///   context: {'type': field.type.getDisplayString()},
/// );
/// ```
/// ---------------------------------------------------------------------------
class TypeParsingException extends CherryPickGeneratorException {
  TypeParsingException(
    super.message, {
    required super.element,
    super.suggestion,
    super.context,
  }) : super(category: 'TYPE_PARSING');
}

/// ---------------------------------------------------------------------------
/// CodeGenerationException
///
/// Thrown on unexpected code generation or formatting failures
/// during generator execution.
///
/// Grouped as category "CODE_GENERATION".
///
/// ## Example:
/// ```dart
/// throw CodeGenerationException(
///   'Could not generate module binding',
///   element: classElement,
///   suggestion: 'Check module class methods and signatures.',
/// );
/// ```
/// ---------------------------------------------------------------------------
class CodeGenerationException extends CherryPickGeneratorException {
  CodeGenerationException(
    super.message, {
    required super.element,
    super.suggestion,
    super.context,
  }) : super(category: 'CODE_GENERATION');
}

/// ---------------------------------------------------------------------------
/// DependencyResolutionException
///
/// Thrown if dependency information (for example, types or names)
/// cannot be resolved during code generation analysis.
///
/// Grouped as category "DEPENDENCY_RESOLUTION".
///
/// ## Example:
/// ```dart
/// throw DependencyResolutionException(
///   'Dependency type not found in scope',
///   element: someElement,
///   suggestion: 'Check CherryPick registration for this type.',
/// );
/// ```
/// ---------------------------------------------------------------------------
class DependencyResolutionException extends CherryPickGeneratorException {
  DependencyResolutionException(
    super.message, {
    required super.element,
    super.suggestion,
    super.context,
  }) : super(category: 'DEPENDENCY_RESOLUTION');
}
