///
/// Copyright 2021 Sergey Penkovsky <sergey.penkovsky@gmail.com>
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///      http://www.apache.org/licenses/LICENSE-2.0
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.
///
import 'package:cherrypick/src/scope.dart';

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
}