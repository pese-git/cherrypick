/// An annotation to declare a class as a singleton.
///
/// This can be used to indicate that only one instance of the class
/// should be created, which is often useful in dependency injection
/// frameworks or service locators.
///
/// Example:
/// ```dart
/// @module()
/// abstract class AppModule extends Module {
///   @singleton()
///   Dio dio() => Dio();
/// }
/// ```
/// Сгенерирует код:
/// ```dart
/// final class $AppModule extends AppModule {
///   @override
///   void builder(Scope currentScope) {
///     bind<Dio>().toProvide(() => dio()).singleton();
///   }
/// }
/// ```
// ignore: camel_case_types
final class singleton {
  /// Creates a [singleton] annotation.
  const singleton();
}
