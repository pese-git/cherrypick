import 'package:cherrypick/cherrypick.dart';
import 'package:flutter/widgets.dart';

///
/// Copyright 2021 Sergey Penkovsky (sergey.penkovsky@gmail.com)
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///      https://www.apache.org/licenses/LICENSE-2.0
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.
///

/// {@template cherrypick_flutter_provider}
/// An [InheritedWidget] that provides convenient integration of CherryPick
/// dependency injection scopes into the Flutter widget tree.
///
/// Place `CherryPickProvider` at the top of your widget subtree to make a
/// [Scope] (or its descendants) available via `CherryPickProvider.of(context)`.
///
/// This is the recommended entry point for connecting CherryPick DI to your 
/// Flutter app or feature area, enabling context-based scope management and
/// DI resolution in child widgets.
///
/// ### Example: Root Integration
/// ```dart
/// void main() {
///   final rootScope = CherryPick.openRootScope()
///     ..installModules([AppModule()]);
///   runApp(
///     CherryPickProvider(
///       child: MyApp(),
///     ),
///   );
/// }
/// 
/// // In any widget:
/// final provider = CherryPickProvider.of(context);
/// final scope = provider.openRootScope();
/// final myService = scope.resolve<MyService>();
/// ```
///
/// ### Example: Subscope for a Feature/Screen
/// ```dart
/// Widget build(BuildContext context) {
///   final provider = CherryPickProvider.of(context);
///   final featureScope = provider.openSubScope(scopeName: 'featureA');
///   return MyFeatureScreen(scope: featureScope);
/// }
/// ```
///
/// You can use [openRootScope] and [openSubScope] as helpers to get/create scopes.
/// {@endtemplate}
final class CherryPickProvider extends InheritedWidget {
  /// Opens (or returns) the application-wide root [Scope].
  ///
  /// Use to make all dependencies available at the top of your widget tree.
  Scope openRootScope() => CherryPick.openRootScope();

  /// Opens a subscope (child [Scope]) with the given [scopeName].
  ///
  /// Useful to create isolated feature/module scopes in widget subtrees.
  /// If [scopeName] is empty, an unnamed scope is created.
  Scope openSubScope({String scopeName = '', String separator = '.'}) =>
      CherryPick.openScope(scopeName: scopeName, separator: separator);

  /// Creates a [CherryPickProvider] and exposes it to the widget subtree.
  ///
  /// Place near the root of your widget tree. Use [child] to provide the subtree.
  const CherryPickProvider({
    super.key,
    required super.child,
  });

  /// Locates the nearest [CherryPickProvider] up the widget tree from [context].
  ///
  /// Throws if not found. Use this to access DI [Scope] controls anywhere below the provider.
  ///
  /// Example:
  /// ```dart
  /// final provider = CherryPickProvider.of(context);
  /// final scope = provider.openRootScope();
  /// ```
  static CherryPickProvider of(BuildContext context) {
    final CherryPickProvider? result =
        context.dependOnInheritedWidgetOfExactType<CherryPickProvider>();
    assert(result != null, 'No CherryPickProvider found in context');
    return result!;
  }

  /// Controls update notifications for dependent widgets.
  ///
  /// Always returns false because the provider itself is stateless:
  /// changes are to the underlying scopes, not the widget.
  @override
  bool updateShouldNotify(CherryPickProvider oldWidget) {
    return false;
  }
}
