import 'package:cherrypick/module.dart';
import 'package:cherrypick/scope.dart';
import 'package:test/test.dart';

void main() {
  group('Without parent scope.', () {
    test('Parent scope is null.', () {
      final scope = Scope(null);
      expect(scope.parentScope, null);
    });

    test('Open sub scope.', () {
      final scope = Scope(null);
      final subScope = scope.openSubScope('subScope');
      expect(scope.openSubScope('subScope'), subScope);
    });

    test("Container throws state error if the value can't be resolved", () {
      final scope = Scope(null);
      expect(() => scope.resolve<String>(), throwsA(isA<StateError>()));
    });

    test('Container resolves value after adding a dependency', () {
      final expectedValue = 'test string';
      final scope = Scope(null)
          .installModules([TestModule<String>(value: expectedValue)]);
      expect(scope.resolve<String>(), expectedValue);
    });
  });

  group('With parent scope.', () {
    /*  
    test(
        "Container bind() throws state error (if it's parent already has a resolver)",
        () {
      final parentScope = new Scope(null)
          .installModules([TestModule<String>(value: "string one")]);
      final scope = new Scope(parentScope);

      expect(
          () => scope.installModules([TestModule<String>(value: "string two")]),
          throwsA(isA<StateError>()));
    });
*/
    test('Container resolve() returns a value from parent container.', () {
      final expectedValue = 5;
      final parentScope = Scope(null);
      final scope = Scope(parentScope);

      parentScope.installModules([TestModule<int>(value: expectedValue)]);

      expect(scope.resolve<int>(), expectedValue);
    });

    test('Container resolve() returns a  several value from parent container.',
        () {
      final expectedIntValue = 5;
      final expectedStringValue = 'Hello world';
      final parentScope = Scope(null).installModules([
        TestModule<int>(value: expectedIntValue),
        TestModule<String>(value: expectedStringValue)
      ]);
      final scope = Scope(parentScope);

      expect(scope.resolve<int>(), expectedIntValue);
      expect(scope.resolve<String>(), expectedStringValue);
    });

    test("Container resolve() throws a state error if parent hasn't value too.",
        () {
      final parentScope = Scope(null);
      final scope = Scope(parentScope);
      expect(() => scope.resolve<int>(), throwsA(isA<StateError>()));
    });
  });
}

class TestModule<T> extends Module {
  final T value;
  final String? name;

  TestModule({required this.value, this.name});
  @override
  void builder(Scope currentScope) {
    if (name == null) {
      bind<T>().toInstance(value);
    } else {
      bind<T>().withName(name!).toInstance(value);
    }
  }
}
