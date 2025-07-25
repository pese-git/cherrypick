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
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'exceptions.dart';

/// Enhanced type parser that uses AST analysis instead of regular expressions
class TypeParser {
  /// Parses a DartType and extracts detailed type information
  static ParsedType parseType(DartType dartType, Element context) {
    try {
      return _parseTypeInternal(dartType, context);
    } catch (e) {
      throw TypeParsingException(
        'Failed to parse type: ${dartType.getDisplayString()}',
        element: context,
        suggestion: 'Ensure the type is properly imported and accessible',
        context: {
          'original_type': dartType.getDisplayString(),
          'error': e.toString(),
        },
      );
    }
  }

  static ParsedType _parseTypeInternal(DartType dartType, Element context) {
    final displayString = dartType.getDisplayString();
    final isNullable = dartType.nullabilitySuffix == NullabilitySuffix.question;

    // Check if it's a Future type
    if (dartType.isDartAsyncFuture) {
      return _parseFutureType(dartType, context, isNullable);
    }

    // Check if it's a generic type (List, Map, etc.)
    if (dartType is ParameterizedType && dartType.typeArguments.isNotEmpty) {
      return _parseGenericType(dartType, context, isNullable);
    }

    // Simple type
    return ParsedType(
      displayString: displayString,
      coreType: displayString.replaceAll('?', ''),
      isNullable: isNullable,
      isFuture: false,
      isGeneric: false,
      typeArguments: [],
    );
  }

  static ParsedType _parseFutureType(
      DartType dartType, Element context, bool isNullable) {
    if (dartType is! ParameterizedType || dartType.typeArguments.isEmpty) {
      throw TypeParsingException(
        'Future type must have a type argument',
        element: context,
        suggestion: 'Use Future<T> instead of raw Future',
        context: {'type': dartType.getDisplayString()},
      );
    }

    final innerType = dartType.typeArguments.first;
    final innerParsed = _parseTypeInternal(innerType, context);

    return ParsedType(
      displayString: dartType.getDisplayString(),
      coreType: innerParsed.coreType,
      isNullable: isNullable || innerParsed.isNullable,
      isFuture: true,
      isGeneric: innerParsed.isGeneric,
      typeArguments: innerParsed.typeArguments,
      innerType: innerParsed,
    );
  }

  static ParsedType _parseGenericType(
      ParameterizedType dartType, Element context, bool isNullable) {
    final typeArguments = dartType.typeArguments
        .map((arg) => _parseTypeInternal(arg, context))
        .toList();

    final baseType = dartType.element?.name ?? dartType.getDisplayString();

    return ParsedType(
      displayString: dartType.getDisplayString(),
      coreType: baseType,
      isNullable: isNullable,
      isFuture: false,
      isGeneric: true,
      typeArguments: typeArguments,
    );
  }

  /// Validates that a type is suitable for dependency injection
  static void validateInjectableType(ParsedType parsedType, Element context) {
    // Check for void type
    if (parsedType.coreType == 'void') {
      throw TypeParsingException(
        'Cannot inject void type',
        element: context,
        suggestion: 'Use a concrete type instead of void',
      );
    }

    // Check for dynamic type (warning)
    if (parsedType.coreType == 'dynamic') {
      // This could be a warning instead of an error
      throw TypeParsingException(
        'Using dynamic type reduces type safety',
        element: context,
        suggestion: 'Consider using a specific type instead of dynamic',
      );
    }

    // Validate nested types for complex generics
    for (final typeArg in parsedType.typeArguments) {
      validateInjectableType(typeArg, context);
    }
  }
}

/// Represents a parsed type with detailed information
class ParsedType {
  /// The full display string of the type (e.g., "Future<List<String>?>")
  final String displayString;

  /// The core type name without nullability and Future wrapper (e.g., "List<String>")
  final String coreType;

  /// Whether the type is nullable
  final bool isNullable;

  /// Whether the type is wrapped in Future
  final bool isFuture;

  /// Whether the type has generic parameters
  final bool isGeneric;

  /// Parsed type arguments for generic types
  final List<ParsedType> typeArguments;

  /// For Future types, the inner type
  final ParsedType? innerType;

  const ParsedType({
    required this.displayString,
    required this.coreType,
    required this.isNullable,
    required this.isFuture,
    required this.isGeneric,
    required this.typeArguments,
    this.innerType,
  });

  /// Returns the type string suitable for code generation
  String get codeGenType {
    if (isFuture && innerType != null) {
      return innerType!.codeGenType;
    }

    // For generic types, include type arguments
    if (isGeneric && typeArguments.isNotEmpty) {
      final args = typeArguments.map((arg) => arg.codeGenType).join(', ');
      return '$coreType<$args>';
    }

    return coreType;
  }

  /// Returns whether this type should use tryResolve instead of resolve
  bool get shouldUseTryResolve => isNullable;

  /// Returns the appropriate resolve method name
  String get resolveMethodName {
    if (isFuture) {
      return shouldUseTryResolve ? 'tryResolveAsync' : 'resolveAsync';
    }
    return shouldUseTryResolve ? 'tryResolve' : 'resolve';
  }

  @override
  String toString() {
    return 'ParsedType(displayString: $displayString, coreType: $coreType, '
        'isNullable: $isNullable, isFuture: $isFuture, isGeneric: $isGeneric)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParsedType &&
        other.displayString == displayString &&
        other.coreType == coreType &&
        other.isNullable == isNullable &&
        other.isFuture == isFuture &&
        other.isGeneric == isGeneric;
  }

  @override
  int get hashCode {
    return displayString.hashCode ^
        coreType.hashCode ^
        isNullable.hashCode ^
        isFuture.hashCode ^
        isGeneric.hashCode;
  }
}
