import 'package:dart_di/scope.dart';

abstract class Factory<T> {
  T createInstance(Scope scope);
}
