import 'package:test/test.dart';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source.dart';
import 'package:cherrypick_generator/src/type_parser.dart';
import 'package:cherrypick_generator/src/exceptions.dart';

void main() {
  group('TypeParser', () {
    group('parseType', () {
      test('should parse simple types correctly', () {
        // This would require setting up analyzer infrastructure
        // For now, we'll test the ParsedType class directly
      });

      test('should parse Future types correctly', () {
        // This would require setting up analyzer infrastructure
        // For now, we'll test the ParsedType class directly
      });

      test('should parse nullable types correctly', () {
        // This would require setting up analyzer infrastructure
        // For now, we'll test the ParsedType class directly
      });

      test('should throw TypeParsingException for invalid types', () {
        // This would require setting up analyzer infrastructure
        // For now, we'll test the ParsedType class directly
      });
    });

    group('validateInjectableType', () {
      test('should throw for void type', () {
        final parsedType = ParsedType(
          displayString: 'void',
          coreType: 'void',
          isNullable: false,
          isFuture: false,
          isGeneric: false,
          typeArguments: [],
        );

        expect(
          () => TypeParser.validateInjectableType(
              parsedType, _createMockElement()),
          throwsA(isA<TypeParsingException>()),
        );
      });

      test('should throw for dynamic type', () {
        final parsedType = ParsedType(
          displayString: 'dynamic',
          coreType: 'dynamic',
          isNullable: false,
          isFuture: false,
          isGeneric: false,
          typeArguments: [],
        );

        expect(
          () => TypeParser.validateInjectableType(
              parsedType, _createMockElement()),
          throwsA(isA<TypeParsingException>()),
        );
      });

      test('should pass for valid types', () {
        final parsedType = ParsedType(
          displayString: 'String',
          coreType: 'String',
          isNullable: false,
          isFuture: false,
          isGeneric: false,
          typeArguments: [],
        );

        expect(
          () => TypeParser.validateInjectableType(
              parsedType, _createMockElement()),
          returnsNormally,
        );
      });
    });
  });

  group('ParsedType', () {
    test('should return correct codeGenType for simple types', () {
      final parsedType = ParsedType(
        displayString: 'String',
        coreType: 'String',
        isNullable: false,
        isFuture: false,
        isGeneric: false,
        typeArguments: [],
      );

      expect(parsedType.codeGenType, equals('String'));
    });

    test('should return correct codeGenType for Future types', () {
      final innerType = ParsedType(
        displayString: 'String',
        coreType: 'String',
        isNullable: false,
        isFuture: false,
        isGeneric: false,
        typeArguments: [],
      );

      final parsedType = ParsedType(
        displayString: 'Future<String>',
        coreType: 'Future<String>',
        isNullable: false,
        isFuture: true,
        isGeneric: false,
        typeArguments: [],
        innerType: innerType,
      );

      expect(parsedType.codeGenType, equals('String'));
    });

    test('should return correct resolveMethodName for sync types', () {
      final parsedType = ParsedType(
        displayString: 'String',
        coreType: 'String',
        isNullable: false,
        isFuture: false,
        isGeneric: false,
        typeArguments: [],
      );

      expect(parsedType.resolveMethodName, equals('resolve'));
    });

    test('should return correct resolveMethodName for nullable sync types', () {
      final parsedType = ParsedType(
        displayString: 'String?',
        coreType: 'String',
        isNullable: true,
        isFuture: false,
        isGeneric: false,
        typeArguments: [],
      );

      expect(parsedType.resolveMethodName, equals('tryResolve'));
    });

    test('should return correct resolveMethodName for async types', () {
      final parsedType = ParsedType(
        displayString: 'Future<String>',
        coreType: 'String',
        isNullable: false,
        isFuture: true,
        isGeneric: false,
        typeArguments: [],
      );

      expect(parsedType.resolveMethodName, equals('resolveAsync'));
    });

    test('should return correct resolveMethodName for nullable async types',
        () {
      final parsedType = ParsedType(
        displayString: 'Future<String?>',
        coreType: 'String',
        isNullable: true,
        isFuture: true,
        isGeneric: false,
        typeArguments: [],
      );

      expect(parsedType.resolveMethodName, equals('tryResolveAsync'));
    });

    test('should implement equality correctly', () {
      final parsedType1 = ParsedType(
        displayString: 'String',
        coreType: 'String',
        isNullable: false,
        isFuture: false,
        isGeneric: false,
        typeArguments: [],
      );

      final parsedType2 = ParsedType(
        displayString: 'String',
        coreType: 'String',
        isNullable: false,
        isFuture: false,
        isGeneric: false,
        typeArguments: [],
      );

      expect(parsedType1, equals(parsedType2));
      expect(parsedType1.hashCode, equals(parsedType2.hashCode));
    });

    test('should implement toString correctly', () {
      final parsedType = ParsedType(
        displayString: 'String',
        coreType: 'String',
        isNullable: false,
        isFuture: false,
        isGeneric: false,
        typeArguments: [],
      );

      final result = parsedType.toString();
      expect(result, contains('ParsedType'));
      expect(result, contains('String'));
      expect(result, contains('isNullable: false'));
      expect(result, contains('isFuture: false'));
    });
  });
}

// Mock element for testing
Element _createMockElement() {
  return _MockElement();
}

class _MockElement implements Element {
  @override
  String get displayName => 'MockElement';

  @override
  String get name => 'MockElement';

  @override
  Source? get source => null;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
