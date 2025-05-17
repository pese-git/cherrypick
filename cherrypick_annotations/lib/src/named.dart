/// An annotation to assign a name or identifier to a class, method, or other element.
///
/// This can be useful for code generation, dependency injection,
/// or providing metadata within a framework.
///
/// Example:
/// ```dart
/// @module()
/// abstract class AppModule extends Module {
///   @named('dio')
///   Dio dio() => Dio();
/// }
/// ```
///
/// Сгенерирует код:
/// ```dart
/// final class $AppModule extends AppModule {
///   @override
///   void builder(Scope currentScope) {
///     bind<Dio>().toProvide(() => dio()).withName('dio').singleton();
///   }
/// }
/// ```
// ignore: camel_case_types
final class named {
  /// The assigned name or identifier.
  final String value;

  /// Creates a [named] annotation with the given [value].
  const named(this.value);
}
