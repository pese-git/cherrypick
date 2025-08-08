import 'package:cherrypick/cherrypick.dart';

class MockLogger implements CherryPickLogger {
  final List<String> infos = [];
  final List<String> warns = [];
  final List<String> errors = [];

  @override
  void info(String message) => infos.add(message);
  @override
  void warn(String message) => warns.add(message);
  @override
  void error(String message, [Object? e, StackTrace? s]) =>
      errors.add(
          '$message${e != null ? ' $e' : ''}${s != null ? '\n$s' : ''}');
}
