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

import 'package:cherrypick/src/binding_resolver.dart';

/// {@template binding_docs}
/// [Binding] configures how a dependency of type [T] is created, provided, or managed in CherryPick DI.
///
/// A [Binding] can:
/// - Register a direct instance
/// - Register a provider (sync/async)
/// - Register a provider supporting dynamic params
/// - Be named (for multi-implementation/keyed injection)
/// - Be marked as [singleton] (single instance within scope)
///
/// ### Examples
///
/// Register a direct instance:
/// ```dart
/// bind<String>().toInstance("Hello, world!");
/// ```
///
/// Register via sync provider:
/// ```dart
/// bind<MyService>().toProvide(() => MyService());
/// ```
///
/// Register via async provider (returns Future):
/// ```dart
/// bind<MyApi>().toProvide(() async => await MyApi.connect());
/// ```
///
/// Register provider with dynamic params:
/// ```dart
/// bind<User>().toProvideWithParams((params) => User(name: params["name"]));
/// ```
///
/// Register with name/key:
/// ```dart
/// bind<Client>().withName("mock").toInstance(MockClient());
/// bind<Client>().withName("prod").toInstance(RealClient());
/// final c = scope.resolve<Client>(named: "mock");
/// ```
///
/// Singleton (same instance reused):
/// ```dart
/// bind<Database>().toProvide(() => Database()).singleton();
/// ```
///
/// {@endtemplate}

import 'package:cherrypick/src/observer.dart';

class Binding<T> {
  late Type _key;
  String? _name;

  BindingResolver<T>? _resolver;

  CherryPickObserver? observer;

  // Deferred logging flags
  bool _createdLogged = false;
  bool _namedLogged = false;
  bool _singletonLogged = false;

  Binding({this.observer}) {
    _key = T;
    // Deferred уведомения observer, не логировать здесь напрямую
  }

  void markCreated() {
    if (!_createdLogged) {
      observer?.onBindingRegistered(
        runtimeType.toString(),
        T,
      );
      _createdLogged = true;
    }
  }

  void markNamed() {
    if (isNamed && !_namedLogged) {
      observer?.onDiagnostic(
        'Binding named: ${T.toString()} name: $_name',
        details: {
          'type': 'Binding',
          'name': T.toString(),
          'nameParam': _name,
          'description': 'named',
        },
      );
      _namedLogged = true;
    }
  }

  void markSingleton() {
    if (isSingleton && !_singletonLogged) {
      observer?.onDiagnostic(
        'Binding singleton: ${T.toString()}${_name != null ? ' name: $_name' : ''}',
        details: {
          'type': 'Binding',
          'name': T.toString(),
          if (_name != null) 'name': _name,
          'description': 'singleton mode enabled',
        },
      );
      _singletonLogged = true;
    }
  }

  void logAllDeferred() {
    markCreated();
    markNamed();
    markSingleton();
  }

  /// Returns the type key used by this binding.
  ///
  /// Usually you don't need to access it directly.
  Type get key => _key;

  /// Returns the name (if any) for this binding.
  /// Useful for named/multi-implementation resolution.
  String? get name => _name;

  /// Returns true if this binding is named (named/keyed binding).
  bool get isNamed => _name != null;

  /// Returns true if this binding is marked as a singleton.
  /// Singleton bindings will only create one instance within the scope.
  bool get isSingleton => _resolver?.isSingleton ?? false;

  BindingResolver<T>? get resolver => _resolver;

  /// Adds a name/key to this binding (for multi-implementation or keyed injection).
  ///
  /// Example:
  /// ```dart
  /// bind<Client>().withName("mock").toInstance(MockClient());
  /// ```
  Binding<T> withName(String name) {
    _name = name;
    return this;
  }

  /// Binds a direct instance (static object) for this type.
  ///
  /// Example:
  /// ```dart
  /// bind<Api>().toInstance(ApiMock());
  /// ```
  ///
  /// **Important limitation:**
  /// If you register several dependencies via [toInstance] inside a [`Module.builder`],
  /// do _not_ use `scope.resolve<T>()` to get objects that are also being registered during the _same_ builder execution.
  /// All [toInstance] bindings are applied sequentially, and at the point of registration,
  /// earlier objects are not yet available for resolve.
  ///
  /// **Correct:**
  /// ```dart
  /// void builder(Scope scope) {
  ///   final a = A();
  ///   final b = B(a);
  ///   bind<A>().toInstance(a);
  ///   bind<B>().toInstance(b);
  /// }
  /// ```
  /// **Wrong:**
  /// ```dart
  /// void builder(Scope scope) {
  ///   bind<A>().toInstance(A());
  ///   bind<B>().toInstance(B(scope.resolve<A>())); // Error! A is not available yet.
  /// }
  /// ```
  /// **Wrong:**
  /// ```dart
  /// void builder(Scope scope) {
  ///   bind<A>().toProvide(() => A());
  ///   bind<B>().toInstance(B(scope.resolve<A>())); // Error! A is not available yet.
  /// }
  /// ```
  /// This restriction only applies to [toInstance] bindings.
  /// With [toProvide]/[toProvideAsync] you may freely use `scope.resolve<T>()` in the builder or provider function.
  Binding<T> toInstance(Instance<T> value) {
    _resolver = InstanceResolver<T>(value);
    return this;
  }

  /// Binds a provider function (sync or async) that creates the instance when resolved.
  ///
  /// Example:
  /// ```dart
  /// bind<Api>().toProvide(() => ApiService());
  /// bind<Db>().toProvide(() async => await openDb());
  /// ```
  Binding<T> toProvide(Provider<T> value) {
    _resolver = ProviderResolver<T>((_) => value.call(), withParams: false);
    return this;
  }

  /// Binds a provider function that takes dynamic params at resolve-time (e.g. for factories).
  ///
  /// Example:
  /// ```dart
  /// bind<User>().toProvideWithParams((params) => User(name: params["name"]));
  /// ```
  Binding<T> toProvideWithParams(ProviderWithParams<T> value) {
    _resolver = ProviderResolver<T>(value, withParams: true);
    return this;
  }

  @Deprecated('Use toInstance instead of toInstanceAsync')
  Binding<T> toInstanceAsync(Instance<T> value) {
    return this.toInstance(value);
  }

  @Deprecated('Use toProvide instead of toProvideAsync')
  Binding<T> toProvideAsync(Provider<T> value) {
    return this.toProvide(value);
  }

  @Deprecated('Use toProvideWithParams instead of toProvideAsyncWithParams')
  Binding<T> toProvideAsyncWithParams(ProviderWithParams<T> value) {
    return this.toProvideWithParams(value);
  }

  /// Marks this binding as singleton (will only create and cache one instance per scope).
  ///
  /// Call this after toProvide/toInstance etc:
  /// ```dart
  /// bind<Api>().toProvide(() => MyApi()).singleton();
  /// ```
  ///
  /// ---
  ///
  /// ⚠️ **Special note: Behavior with parametric providers (`toProvideWithParams`/`toProvideAsyncWithParams`):**
  ///
  /// If you declare a binding using `.toProvideWithParams(...)` (or its async variant) and then chain `.singleton()`, only the **very first** `resolve<T>(params: ...)` will use its parameters;
  /// every subsequent call (regardless of params) will return the same (cached) instance.
  ///
  /// Example:
  /// ```dart
  /// bind<Service>().toProvideWithParams((params) => Service(params)).singleton();
  /// final a = scope.resolve<Service>(params: 1); // creates Service(1)
  /// final b = scope.resolve<Service>(params: 2); // returns Service(1)
  /// print(identical(a, b)); // true
  /// ```
  ///
  /// Use this pattern only if you want a master singleton. If you expect a new instance per params, **do not** use `.singleton()` on parameterized providers.
  Binding<T> singleton() {
    _resolver?.toSingleton();
    return this;
  }

  /// Resolves the instance synchronously (if binding supports sync access).
  ///
  /// Returns the created/found instance or null.
  ///
  /// Example:
  /// ```dart
  /// final s = scope.resolveSync<String>();
  /// ```
  T? resolveSync([dynamic params]) {
    final res = resolver?.resolveSync(params);
    if (res != null) {
      observer?.onDiagnostic(
        'Binding resolved instance: ${T.toString()}',
        details: {
          if (_name != null) 'name': _name,
          'method': 'resolveSync',
          'description': 'object created/resolved',
        },
      );
    } else {
      observer?.onWarning(
        'resolveSync returned null: ${T.toString()}',
        details: {
          if (_name != null) 'name': _name,
          'method': 'resolveSync',
          'description': 'resolveSync returned null',
        },
      );
    }
    return res;
  }

  /// Resolves the instance asynchronously (if binding supports async/future access).
  ///
  /// Returns a [Future] with the instance, or null if unavailable.
  ///
  /// Example:
  /// ```dart
  /// final user = await scope.resolveAsync<User>();
  /// ```
  Future<T>? resolveAsync([dynamic params]) {
    final future = resolver?.resolveAsync(params);
    if (future != null) {
      future
          .then((res) => observer?.onDiagnostic(
                'Future resolved for: ${T.toString()}',
                details: {
                  if (_name != null) 'name': _name,
                  'method': 'resolveAsync',
                  'description': 'Future resolved',
                },
              ))
          .catchError((e, s) => observer?.onError(
                'resolveAsync error: ${T.toString()}',
                e,
                s,
              ));
    } else {
      observer?.onWarning(
        'resolveAsync returned null: ${T.toString()}',
        details: {
          if (_name != null) 'name': _name,
          'method': 'resolveAsync',
          'description': 'resolveAsync returned null',
        },
      );
    }
    return future;
  }
}
