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

import 'package:cherrypick/cherrypick.dart';
import 'package:talker/talker.dart';

/// An implementation of [CherryPickObserver] that logs all DI container events
/// through the [Talker] logging system.
///
/// This observer allows you to automatically route all important events from the
/// CherryPick DI container (such as instance creation, cache hits, errors, module install,
/// scope lifecycle events, and more) directly to your Talker logger. It is useful for
/// debugging, monitoring, and analytics.
///
/// ## Example usage
/// ```dart
/// import 'package:talker/talker.dart';
/// import 'package:cherrypick/cherrypick.dart';
/// import 'package:talker_cherrypick_logger/talker_cherrypick_logger.dart';
///
/// final talker = Talker();
/// final observer = TalkerCherryPickObserver(talker);
///
/// // Pass the observer to your CherryPick root scope (or any scope)
/// CherryPick.openRootScope(observer: observer);
///
/// // Now all DI container events will be logged with Talker
/// ```
///
/// ## Logged event examples
/// - "[binding][CherryPick] MyService — MyServiceImpl (scope: root)"
/// - "[create][CherryPick] MyService — MyServiceImpl => Instance(...) (scope: root)"
/// - "[cache hit][CherryPick] MyService — MyServiceImpl (scope: root)"
/// - "[cycle][CherryPick] Detected: A -> B -> C -> A (scope: root)"
///
/// ## Log levels mapping
/// - `info`: regular events (registered, resolved, created, disposed, modules, scopes, cache hits/misses)
/// - `warning`: cycles, cherry pick warnings
/// - `verbose`: diagnostics
/// - `handle`: errors (includes error object/stack)
class TalkerCherryPickObserver implements CherryPickObserver {
  /// The target [Talker] instance to send logs to.
  final Talker talker;

  /// Creates a [TalkerCherryPickObserver] that routes CherryPick DI events into the given [Talker] logger.
  TalkerCherryPickObserver(this.talker);

  /// Called when a binding (dependency mapping) is registered in the DI container.
  @override
  void onBindingRegistered(String name, Type type, {String? scopeName}) {
    talker.info('[binding][CherryPick] $name — $type (scope: $scopeName)');
  }

  /// Called when an instance is requested (before creation or retrieval).
  @override
  void onInstanceRequested(String name, Type type, {String? scopeName}) {
    talker.info('[request][CherryPick] $name — $type (scope: $scopeName)');
  }

  /// Called when a new instance is created.
  @override
  void onInstanceCreated(String name, Type type, Object instance, {String? scopeName}) {
    talker.info('[create][CherryPick] $name — $type => $instance (scope: $scopeName)');
  }

  /// Called when an instance is disposed.
  @override
  void onInstanceDisposed(String name, Type type, Object instance, {String? scopeName}) {
    talker.info('[dispose][CherryPick] $name — $type => $instance (scope: $scopeName)');
  }

  /// Called when modules are installed.
  @override
  void onModulesInstalled(List<String> modules, {String? scopeName}) {
    talker.info('[modules installed][CherryPick] ${modules.join(', ')} (scope: $scopeName)');
  }

  /// Called when modules are removed.
  @override
  void onModulesRemoved(List<String> modules, {String? scopeName}) {
    talker.info('[modules removed][CherryPick] ${modules.join(', ')} (scope: $scopeName)');
  }

  /// Called when a DI scope is opened.
  @override
  void onScopeOpened(String name) {
    talker.info('[scope opened][CherryPick] $name');
  }

  /// Called when a DI scope is closed.
  @override
  void onScopeClosed(String name) {
    talker.info('[scope closed][CherryPick] $name');
  }

  /// Called if the DI container detects a cycle in the dependency graph.
  @override
  void onCycleDetected(List<String> chain, {String? scopeName}) {
    talker.warning('[cycle][CherryPick] Detected: ${chain.join(' -> ')}${scopeName != null ? ' (scope: $scopeName)' : ''}');
  }

  /// Called when an instance is found in the cache.
  @override
  void onCacheHit(String name, Type type, {String? scopeName}) {
    talker.info('[cache hit][CherryPick] $name — $type (scope: $scopeName)');
  }

  /// Called when an instance is NOT found in the cache and will be created.
  @override
  void onCacheMiss(String name, Type type, {String? scopeName}) {
    talker.info('[cache miss][CherryPick] $name — $type (scope: $scopeName)');
  }

  /// Called for generic diagnostic/debug events.
  @override
  void onDiagnostic(String message, {Object? details}) {
    talker.verbose('[diagnostic][CherryPick] $message ${details ?? ''}');
  }

  /// Called for non-fatal DI container warnings.
  @override
  void onWarning(String message, {Object? details}) {
    talker.warning('[warn][CherryPick] $message ${details ?? ''}');
  }

  /// Called for error events with optional stack trace.
  @override
  void onError(String message, Object? error, StackTrace? stackTrace) {
    talker.handle(error ?? '[CherryPick] $message', stackTrace, '[error][CherryPick] $message');
  }
}