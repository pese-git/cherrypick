import 'package:dart_di/experimental/scope.dart';

abstract class Factory<T> {
  T createInstance(Scope scope);
}
