import 'package:cherrypick/cherrypick.dart';
import 'package:flutter/widgets.dart';

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

class CherryPickProvider extends InheritedWidget {
  // Holds a reference to the root scope object
  final Scope rootScope;

  // Constructor for CherryPickProvider. Initializes with a required rootScope and child widget.
  const CherryPickProvider({
    super.key,
    required this.rootScope,
    required super.child,
  });

  // Method to access the nearest CherryPickProvider instance from the context
  static CherryPickProvider of(BuildContext context) {
    // Looks up the widget tree for an instance of CherryPickProvider
    final CherryPickProvider? result =
        context.dependOnInheritedWidgetOfExactType<CherryPickProvider>();
    // Assert to ensure a CherryPickProvider is present in the context
    assert(result != null, 'No CherryPickProvider found in context');
    return result!;
  }

  // Determines whether the widget should notify dependents when it changes
  @override
  bool updateShouldNotify(CherryPickProvider oldWidget) {
    // Notify if the rootScope has changed
    return rootScope != oldWidget.rootScope;
  }
}
