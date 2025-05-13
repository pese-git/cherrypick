//
// Copyright 2021 Sergey Penkovsky <sergey.penkovsky@gmail.com>
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//      http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
import 'package:cherrypick/src/scope.dart';
import 'package:meta/meta.dart';

Scope? _rootScope;

class CherryPick {
  /// RU: Метод открывает главный [Scope].
  /// ENG: The method opens the main [Scope].
  ///
  /// return
  static Scope openRootScope() {
    _rootScope ??= Scope(null);
    return _rootScope!;
  }

  /// RU: Метод закрывает главный [Scope].
  /// ENG: The method close the main [Scope].
  ///
  ///
  static void closeRootScope() {
    if (_rootScope != null) {
      _rootScope = null;
    }
  }

  /// RU: Метод открывает  дочерний [Scope].
  /// ENG: The method open the child [Scope].
  ///
  /// Дочерний [Scope] открывается с [scopeName]
  /// Child [Scope] open with [scopeName]
  ///
  /// Example:
  /// ```
  /// final String scopeName = 'firstScope.secondScope';
  /// final subScope = CherryPick.openScope(scopeName);
  /// ```
  ///
  ///
  @experimental
  static Scope openScope({String scopeName = '', String separator = '.'}) {
    if (scopeName.isEmpty) {
      return openRootScope();
    }

    final nameParts = scopeName.split(separator);
    if (nameParts.isEmpty) {
      throw Exception('Can not open sub scope because scopeName can not split');
    }

    return nameParts.fold(
        openRootScope(),
        (Scope previousValue, String element) =>
            previousValue.openSubScope(element));
  }

  /// RU: Метод открывает  дочерний [Scope].
  /// ENG: The method open the child [Scope].
  ///
  /// Дочерний [Scope] открывается с [scopeName]
  /// Child [Scope] open with [scopeName]
  ///
  /// Example:
  /// ```
  /// final String scopeName = 'firstScope.secondScope';
  /// final subScope = CherryPick.closeScope(scopeName);
  /// ```
  ///
  ///
  @experimental
  static void closeScope({String scopeName = '', String separator = '.'}) {
    if (scopeName.isEmpty) {
      closeRootScope();
    }

    final nameParts = scopeName.split(separator);
    if (nameParts.isEmpty) {
      throw Exception(
          'Can not close sub scope because scopeName can not split');
    }

    if (nameParts.length > 1) {
      final lastPart = nameParts.removeLast();

      final scope = nameParts.fold(
          openRootScope(),
          (Scope previousValue, String element) =>
              previousValue.openSubScope(element));
      scope.closeSubScope(lastPart);
    } else {
      openRootScope().closeSubScope(nameParts[0]);
    }
  }
}
