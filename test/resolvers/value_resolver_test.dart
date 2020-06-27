import 'package:dart_di/resolvers/value_resolver.dart';
import 'package:test/test.dart';

void main() {
  test('Value resolver resolves with selected value', () {
    var a = 3;
    final valResolver = new ValueResolver(a);

    expect(valResolver.resolve(), a);
  });
}
