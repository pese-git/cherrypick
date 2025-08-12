//
// Copyright 2021 Sergey Penkovsky (sergey.penkovsky@gmail.com)
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//      https://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
import 'dart:collection';

import 'package:cherrypick/src/binding.dart';
import 'package:cherrypick/src/scope.dart';

/// Represents a DI module—a reusable group of dependency bindings.
/// 
/// Extend [Module] to declaratively group related [Binding] definitions,
/// then install your module(s) into a [Scope] for dependency resolution.
/// 
/// Modules make it easier to organize your DI configuration for features, layers,
/// infrastructure, or integration, and support modular app architecture.
/// 
/// Usage example:
/// ```dart
/// class AppModule extends Module {
///   @override
///   void builder(Scope currentScope) {
///     bind<NetworkService>().toProvide(() => NetworkService());
///     bind<AuthService>().toProvide(() => AuthService(currentScope.resolve<NetworkService>()));
///     bind<Config>().toInstance(Config.dev());
///   }
/// }
/// 
/// // Installing the module into the root DI scope:
/// final rootScope = CherryPick.openRootScope();
/// rootScope.installModules([AppModule()]);
/// ```
/// 
/// Combine several modules and submodules to implement scalable architectures.
///
abstract class Module {
  final Set<Binding> _bindingSet = HashSet();

  /// Begins the declaration of a new binding within this module.
  ///
  /// Typically used within [builder] to register all needed dependency bindings.
  ///
  /// Example:
  /// ```dart
  /// bind<Api>().toProvide(() => MockApi());
  /// bind<Config>().toInstance(Config.dev());
  /// ```
  Binding<T> bind<T>() {
    final binding = Binding<T>();
    _bindingSet.add(binding);
    return binding;
  }

  /// Returns the set of all [Binding] instances registered in this module.
  ///
  /// This is typically used internally by [Scope] during module installation,
  /// but can also be used for diagnostics or introspection.
  Set<Binding> get bindingSet => _bindingSet;

  /// Abstract method where all dependency bindings are registered.
  ///
  /// Override this method in your custom module subclass to declare
  /// all dependency bindings to be provided by this module.
  ///
  /// The provided [currentScope] can be used for resolving other dependencies,
  /// accessing configuration, or controlling binding behavior dynamically.
  ///
  /// Example (with dependency chaining):
  /// ```dart
  /// @override
  /// void builder(Scope currentScope) {
  ///   bind<ApiClient>().toProvide(() => RestApi());
  ///   bind<UserRepo>().toProvide(() => UserRepo(currentScope.resolve<ApiClient>()));
  /// }
  /// ```
  void builder(Scope currentScope);
}
