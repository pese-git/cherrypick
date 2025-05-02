import 'package:cherrypick/cherrypick.dart';
import 'package:flutter/widgets.dart';

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
