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

import 'dart:async';

/// An interface for resources that require explicit cleanup, used by the CherryPick dependency injection container.
///
/// If an object implements [Disposable], the CherryPick DI container will automatically call [dispose]
/// when the corresponding scope is cleaned up. Use [Disposable] for closing streams, files, controllers, services, etc.
/// Both synchronous and asynchronous cleanup is supported:
/// - For sync disposables, implement [dispose] as a `void` or simply return nothing.
/// - For async disposables, implement [dispose] returning a [Future].
///
/// Example: Synchronous Disposable
/// ```dart
/// class MyLogger implements Disposable {
///   void dispose() {
///     print('Logger closed!');
///   }
/// }
/// ```
///
/// Example: Asynchronous Disposable
/// ```dart
/// class MyConnection implements Disposable {
///   @override
///   Future<void> dispose() async {
///     await connection.close();
///   }
/// }
/// ```
///
/// Usage with CherryPick DI Module
/// ```dart
/// final scope = openRootScope();
/// scope.installModules([
///   Module((b) {
///     b.bind<MyLogger>((_) => MyLogger());
///     b.bindAsync<MyConnection>((_) async => MyConnection());
///   }),
/// ]);
/// // ...
/// await scope.close(); // will automatically call dispose on all Disposables
/// ```
///
/// This pattern ensures that all resources are released safely and automatically when the scope is destroyed.
abstract class Disposable {
  /// Releases all resources held by this object.
  ///
  /// Implement cleanup logic (closing streams, sockets, files, etc.) within this method.
  /// Return a [Future] for async cleanup, or nothing (`void`) for synchronous cleanup.
  FutureOr<void> dispose();
}
