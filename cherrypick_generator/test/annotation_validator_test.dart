import 'package:test/test.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source.dart';
import 'package:cherrypick_generator/src/annotation_validator.dart';
import 'package:cherrypick_generator/src/exceptions.dart';

void main() {
  group('AnnotationValidator', () {
    group('validateMethodAnnotations', () {
      test('should pass for valid @instance method', () {
        final method = _createMockMethod(
          name: 'createService',
          annotations: ['instance'],
        );

        expect(
          () => AnnotationValidator.validateMethodAnnotations(method),
          returnsNormally,
        );
      });

      test('should pass for valid @provide method', () {
        final method = _createMockMethod(
          name: 'createService',
          annotations: ['provide'],
        );

        expect(
          () => AnnotationValidator.validateMethodAnnotations(method),
          returnsNormally,
        );
      });

      test('should throw for method with both @instance and @provide', () {
        final method = _createMockMethod(
          name: 'createService',
          annotations: ['instance', 'provide'],
        );

        expect(
          () => AnnotationValidator.validateMethodAnnotations(method),
          throwsA(isA<AnnotationValidationException>()),
        );
      });

      test('should throw for method with @params but no @provide', () {
        final method = _createMockMethod(
          name: 'createService',
          annotations: ['instance', 'params'],
        );

        expect(
          () => AnnotationValidator.validateMethodAnnotations(method),
          throwsA(isA<AnnotationValidationException>()),
        );
      });

      test('should throw for method with neither @instance nor @provide', () {
        final method = _createMockMethod(
          name: 'createService',
          annotations: ['singleton'],
        );

        expect(
          () => AnnotationValidator.validateMethodAnnotations(method),
          throwsA(isA<AnnotationValidationException>()),
        );
      });

      test('should pass for @provide method with @params', () {
        final method = _createMockMethod(
          name: 'createService',
          annotations: ['provide', 'params'],
        );

        expect(
          () => AnnotationValidator.validateMethodAnnotations(method),
          returnsNormally,
        );
      });

      test('should pass for @singleton method', () {
        final method = _createMockMethod(
          name: 'createService',
          annotations: ['provide', 'singleton'],
        );

        expect(
          () => AnnotationValidator.validateMethodAnnotations(method),
          returnsNormally,
        );
      });
    });

    group('validateFieldAnnotations', () {
      test('should pass for valid @inject field', () {
        final field = _createMockField(
          name: 'service',
          annotations: ['inject'],
          type: 'String',
        );

        expect(
          () => AnnotationValidator.validateFieldAnnotations(field),
          returnsNormally,
        );
      });

      test('should throw for @inject field with void type', () {
        final field = _createMockField(
          name: 'service',
          annotations: ['inject'],
          type: 'void',
        );

        expect(
          () => AnnotationValidator.validateFieldAnnotations(field),
          throwsA(isA<AnnotationValidationException>()),
        );
      });

      test('should pass for non-inject field', () {
        final field = _createMockField(
          name: 'service',
          annotations: [],
          type: 'String',
        );

        expect(
          () => AnnotationValidator.validateFieldAnnotations(field),
          returnsNormally,
        );
      });
    });

    group('validateClassAnnotations', () {
      test('should pass for valid @module class', () {
        final classElement = _createMockClass(
          name: 'AppModule',
          annotations: ['module'],
          methods: [
            _createMockMethod(name: 'createService', annotations: ['provide']),
          ],
        );

        expect(
          () => AnnotationValidator.validateClassAnnotations(classElement),
          returnsNormally,
        );
      });

      test('should throw for @module class with no public methods', () {
        final classElement = _createMockClass(
          name: 'AppModule',
          annotations: ['module'],
          methods: [],
        );

        expect(
          () => AnnotationValidator.validateClassAnnotations(classElement),
          throwsA(isA<AnnotationValidationException>()),
        );
      });

      test('should throw for @module class with unannotated public methods', () {
        final classElement = _createMockClass(
          name: 'AppModule',
          annotations: ['module'],
          methods: [
            _createMockMethod(name: 'createService', annotations: []),
          ],
        );

        expect(
          () => AnnotationValidator.validateClassAnnotations(classElement),
          throwsA(isA<AnnotationValidationException>()),
        );
      });

      test('should pass for valid @injectable class', () {
        final classElement = _createMockClass(
          name: 'AppService',
          annotations: ['injectable'],
          fields: [
            _createMockField(name: 'dependency', annotations: ['inject'], type: 'String', isFinal: true),
          ],
        );

        expect(
          () => AnnotationValidator.validateClassAnnotations(classElement),
          returnsNormally,
        );
      });

      test('should pass for @injectable class with no inject fields', () {
        final classElement = _createMockClass(
          name: 'AppService',
          annotations: ['injectable'],
          fields: [
            _createMockField(name: 'dependency', annotations: [], type: 'String'),
          ],
        );

        expect(
          () => AnnotationValidator.validateClassAnnotations(classElement),
          returnsNormally,
        );
      });

      test('should throw for @injectable class with non-final inject fields', () {
        final classElement = _createMockClass(
          name: 'AppService',
          annotations: ['injectable'],
          fields: [
            _createMockField(
              name: 'dependency',
              annotations: ['inject'],
              type: 'String',
              isFinal: false,
            ),
          ],
        );

        expect(
          () => AnnotationValidator.validateClassAnnotations(classElement),
          throwsA(isA<AnnotationValidationException>()),
        );
      });
      
      test('should pass for @injectable class with final inject fields', () {
        final classElement = _createMockClass(
          name: 'AppService',
          annotations: ['injectable'],
          fields: [
            _createMockField(
              name: 'dependency',
              annotations: ['inject'],
              type: 'String',
              isFinal: true,
            ),
          ],
        );

        expect(
          () => AnnotationValidator.validateClassAnnotations(classElement),
          returnsNormally,
        );
      });
    });
  });
}

// Mock implementations for testing
MethodElement _createMockMethod({
  required String name,
  required List<String> annotations,
}) {
  return _MockMethodElement(name, annotations);
}

FieldElement _createMockField({
  required String name,
  required List<String> annotations,
  required String type,
  bool isFinal = false,
}) {
  return _MockFieldElement(name, annotations, type, isFinal);
}

ClassElement _createMockClass({
  required String name,
  required List<String> annotations,
  List<MethodElement> methods = const [],
  List<FieldElement> fields = const [],
}) {
  return _MockClassElement(name, annotations, methods, fields);
}

class _MockMethodElement implements MethodElement {
  final String _name;
  final List<String> _annotations;

  _MockMethodElement(this._name, this._annotations);

  @override
  Source get source => _MockSource();

  @override
  String get displayName => _name;

  @override
  String get name => _name;

  @override
  List<ElementAnnotation> get metadata => _annotations.map((a) => _MockElementAnnotation(a)).toList();

  @override
  bool get isPublic => true;

  @override
  List<ParameterElement> get parameters => [];

  @override
  DartType get returnType => _MockDartType('String');

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockFieldElement implements FieldElement {
  final String _name;
  final List<String> _annotations;
  final String _type;
  final bool _isFinal;

  _MockFieldElement(this._name, this._annotations, this._type, this._isFinal);

  @override
  Source get source => _MockSource();

  @override
  String get displayName => _name;

  @override
  String get name => _name;

  @override
  List<ElementAnnotation> get metadata => _annotations.map((a) => _MockElementAnnotation(a)).toList();

  @override
  bool get isFinal => _isFinal;

  @override
  DartType get type => _MockDartType(_type);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockClassElement implements ClassElement {
  final String _name;
  final List<String> _annotations;
  final List<MethodElement> _methods;
  final List<FieldElement> _fields;

  _MockClassElement(this._name, this._annotations, this._methods, this._fields);

  @override
  Source get source => _MockSource();

  @override
  String get displayName => _name;

  @override
  String get name => _name;

  @override
  List<ElementAnnotation> get metadata => _annotations.map((a) => _MockElementAnnotation(a)).toList();

  @override
  List<MethodElement> get methods => _methods;

  @override
  List<FieldElement> get fields => _fields;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockElementAnnotation implements ElementAnnotation {
  final String _type;

  _MockElementAnnotation(this._type);

  @override
  DartObject? computeConstantValue() {
    return _MockDartObject(_type);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockDartObject implements DartObject {
  final String _type;

  _MockDartObject(this._type);

  @override
  DartType? get type => _MockDartType(_type);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockDartType implements DartType {
  final String _name;

  _MockDartType(this._name);

  @override
  String getDisplayString({bool withNullability = true}) => _name;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class _MockSource implements Source {
  @override
  String get fullName => 'mock_source.dart';

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
