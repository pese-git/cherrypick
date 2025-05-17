/// An annotation used to mark a Dart class or library as a module.
///
/// This annotation can be used for tooling, code generation,
/// or to provide additional metadata about the module.
///
/// Example:
/// ```dart
/// @module()
/// abstract class AppModule extends Module {
/// }
/// ```
/// Сгенерирует код:
/// ```dart
/// final class $AppModule extends AppModule {
///   @override
///   void builder(Scope currentScope) {
///
///   }
/// }
// ignore: camel_case_types
final class module {
  /// Creates a [module] annotation.
  const module();
}
