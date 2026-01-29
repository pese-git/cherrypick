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
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'exceptions.dart';

/// Utility for analyzing and parsing Dart types for CherryPick DI code generation.
///
/// This type parser leverages the Dart analyzer AST to extract nuanced information
/// from Dart types encountered in the source code, in particular for dependency
/// injection purposes. It is capable of extracting nullability, generics,
/// and Future-related metadata with strong guarantees and handles even nested generics.
///
/// # Example usage for parsing types:
/// ```dart
/// final parsed = TypeParser.parseType(method.returnType, method);
/// print(parsed);
/// print(parsed.resolveMethodName); // e.g. "resolveAsync" or "tryResolve"
/// ```
///
/// # Supported scenarios:
/// - Nullable types (e.g., `List<String>?`)
/// - Generic types (e.g., `Map<String, User>`)
/// - Async types (`Future<T>`, including nested generics)
/// - Validation for DI compatibility (throws for `void`, warns on `dynamic`)
class TypeParser {
  /// Parses a [DartType] and extracts detailed type information for use in code generation.
  ///
  /// If a type is not suitable or cannot be parsed, a [TypeParsingException] is thrown.
  ///
  /// Example:
  /// ```dart
  /// final parsed = TypeParser.parseType(field.type, field);
  /// if (parsed.isNullable) print('Field is nullable');
  /// ```
  static ParsedType parseType(DartType dartType, Element2 context) {
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

  static ParsedType _parseTypeInternal(DartType dartType, Element2 context) {
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

    // Simple type (non-generic, non-Future)
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
    DartType dartType,
    Element2 context,
    bool isNullable,
  ) {
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
    ParameterizedType dartType,
    Element2 context,
    bool isNullable,
  ) {
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

  /// Validates that a parsed type is suitable for dependency injection.
  ///
  /// Throws [TypeParsingException] for void and may warn for dynamic.
  ///
  /// Example:
  /// ```dart
  /// final parsed = TypeParser.parseType(field.type, field);
  /// TypeParser.validateInjectableType(parsed, field);
  /// ```
  static void validateInjectableType(ParsedType parsedType, Element2 context) {
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

/// Represents a parsed type with full metadata for code generation.
class ParsedType {
  /// The full display string of the type (e.g., "Future<List<String>?>")
  final String displayString;

  /// The core type name without nullability and Future wrapper (e.g., "List<String>")
  final String coreType;

  /// True if nullable (has `?`)
  final bool isNullable;

  /// True if this type is a `Future<T>`
  final bool isFuture;

  /// True if the type is a generic type (`List<T>`)
  final bool isGeneric;

  /// List of parsed type arguments in generics, if any.
  final List<ParsedType> typeArguments;

  /// For `Future<T>`, this is the type inside the `Future`.
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

  /// Generates the type string suitable for code generation.
  ///
  /// - For futures, the codegen type of the inner type is returned
  /// - For generics, returns e.g. `List<User>`
  /// - For plain types, just the name
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

  /// True if this type should use `tryResolve` instead of `resolve` for DI.
  bool get shouldUseTryResolve => isNullable;

  /// Returns the method name for DI, e.g. "resolve", "tryResolveAsync", etc.
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
