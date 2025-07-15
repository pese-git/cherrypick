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

/// Enhanced exception class for CherryPick generator with detailed context information
class CherryPickGeneratorException extends InvalidGenerationSourceError {
  final String category;
  final String? suggestion;
  final Map<String, dynamic>? context;

  CherryPickGeneratorException(
    String message, {
    required Element element,
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
    Element element,
  ) {
    final buffer = StringBuffer();
    
    // Header with category
    buffer.writeln('[$category] $message');
    
    // Element context
    buffer.writeln('');
    buffer.writeln('Context:');
    buffer.writeln('  Element: ${element.displayName}');
    buffer.writeln('  Type: ${element.runtimeType}');
    buffer.writeln('  Location: ${element.source?.fullName ?? 'unknown'}');
    
    // Note: enclosingElement may not be available in all analyzer versions
    try {
      final enclosing = (element as dynamic).enclosingElement;
      if (enclosing != null) {
        buffer.writeln('  Enclosing: ${enclosing.displayName}');
      }
    } catch (e) {
      // Ignore if enclosingElement is not available
    }
    
    // Additional context
    if (context != null && context.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Additional Context:');
      context.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }
    
    // Suggestion
    if (suggestion != null) {
      buffer.writeln('');
      buffer.writeln('💡 Suggestion: $suggestion');
    }
    
    return buffer.toString();
  }
}

/// Specific exception types for different error categories
class AnnotationValidationException extends CherryPickGeneratorException {
  AnnotationValidationException(
    String message, {
    required Element element,
    String? suggestion,
    Map<String, dynamic>? context,
  }) : super(
          message,
          element: element,
          category: 'ANNOTATION_VALIDATION',
          suggestion: suggestion,
          context: context,
        );
}

class TypeParsingException extends CherryPickGeneratorException {
  TypeParsingException(
    String message, {
    required Element element,
    String? suggestion,
    Map<String, dynamic>? context,
  }) : super(
          message,
          element: element,
          category: 'TYPE_PARSING',
          suggestion: suggestion,
          context: context,
        );
}

class CodeGenerationException extends CherryPickGeneratorException {
  CodeGenerationException(
    String message, {
    required Element element,
    String? suggestion,
    Map<String, dynamic>? context,
  }) : super(
          message,
          element: element,
          category: 'CODE_GENERATION',
          suggestion: suggestion,
          context: context,
        );
}

class DependencyResolutionException extends CherryPickGeneratorException {
  DependencyResolutionException(
    String message, {
    required Element element,
    String? suggestion,
    Map<String, dynamic>? context,
  }) : super(
          message,
          element: element,
          category: 'DEPENDENCY_RESOLUTION',
          suggestion: suggestion,
          context: context,
        );
}
