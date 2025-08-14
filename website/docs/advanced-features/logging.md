---
sidebar_position: 2
---

# Logging

CherryPick lets you log all dependency injection (DI) events and errors using a flexible observer mechanism.

## Custom Observers
You can pass any implementation of `CherryPickObserver` to your root scope or any sub-scope.
This allows centralized and extensible logging, which you can direct to print, files, visualization frameworks, external loggers, or systems like [Talker](https://pub.dev/packages/talker).

### Example: Printing All Events

```dart
import 'package:cherrypick/cherrypick.dart';

void main() {
  // Use the built-in PrintCherryPickObserver for console logs
  final observer = PrintCherryPickObserver();
  final scope = CherryPick.openRootScope(observer: observer);
  // All DI actions and errors will now be printed!
}
```

### Example: Advanced Logging with Talker

For richer logging, analytics, or UI overlays, use an advanced observer such as [talker_cherrypick_logger](../talker_cherrypick_logger):

```dart
import 'package:cherrypick/cherrypick.dart';
import 'package:talker/talker.dart';
import 'package:talker_cherrypick_logger/talker_cherrypick_logger.dart';

void main() {
  final talker = Talker();
  final observer = TalkerCherryPickObserver(talker);
  CherryPick.openRootScope(observer: observer);
  // All container events go to the Talker log system!
}
```

## Default Behavior
- By default, logging is silent (`SilentCherryPickObserver`) for production, with no output unless you supply an observer.
- You can configure observers **per scope** for isolated, test-specific, or feature-specific logging.

## Observer Capabilities
Events you can observe and log:
- Dependency registration
- Instance requests, creations, disposals
- Module installs/removals
- Scope opening/closing
- Cache hits/misses
- Cycle detection
- Diagnostics, warnings, errors

Just implement or extend `CherryPickObserver` and direct messages anywhere you want!

## When to Use
- Enable verbose logging and debugging in development or test builds.
- Route logs to your main log system or analytics.
- Hook into DI lifecycle for profiling or monitoring.