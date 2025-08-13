# talker_cherrypick_logger

An integration package that allows you to log [CherryPick](https://github.com/pese-dot-work/cherrypick) Dependency Injection (DI) container events using the [Talker](https://pub.dev/packages/talker) logging system.  
All CherryPick lifecycle events, instance creations, cache operations, module activities, cycles, and errors are routed directly to your Talker logger for easy debugging and advanced diagnostics.

---

## Features

- **Automatic DI container logging:**  
  All core CherryPick events (instance creation/disposal, cache hits/misses, module install/removal, scopes, cycles, errors) are logged through Talker.
- **Flexible log levels:**  
  Each event uses the appropriate Talker log level (`info`, `warning`, `verbose`, `handle` for errors).
- **Works with any Talker setup:**  
  No extra dependencies required except Talker and CherryPick.
- **Improves debugging and DI transparency** in both development and production.

---

## Getting started

### 1. Add dependencies

Install the package **from [pub.dev](https://pub.dev/packages/talker_cherrypick_logger)**:

In your `pubspec.yaml`:
```yaml
dependencies:
  cherrypick: ^latest
  talker: ^latest
  talker_cherrypick_logger: ^latest
```

### 2. Import the package
```dart
import 'package:talker/talker.dart';
import 'package:cherrypick/cherrypick.dart';
import 'package:talker_cherrypick_logger/talker_cherrypick_logger.dart';
```

---

## Usage

### Basic integration

1. **Create a Talker instance** (optionally customize Talker as you wish):
    ```dart
    final talker = Talker();
    ```

2. **Create the observer and pass it to CherryPick:**
    ```dart
    final observer = TalkerCherryPickObserver(talker);

    // On DI setup, pass observer when opening (or re-opening) root or any custom scope
    CherryPick.openRootScope(observer: observer);
    ```

3. **Now all DI events appear in your Talker logs!**

#### Example log output

- `[binding][CherryPick] MyService — MyServiceImpl (scope: root)`
- `[create][CherryPick] MyService — MyServiceImpl => Instance(...) (scope: root)`
- `[cache hit][CherryPick] MyService — MyServiceImpl (scope: root)`
- `[cycle][CherryPick] Detected: A -> B -> C -> A (scope: root)`
- `[error][CherryPick] Failed to resolve dependency`
- `[diagnostic][CherryPick] Cache cleared`

#### How it works

`TalkerCherryPickObserver` implements `CherryPickObserver` and routes all methods/events to Talker:
- Regular events: `.info()`  
- DI Warnings and cycles: `.warning()`  
- Diagnostics: `.verbose()`  
- Errors: `.handle()` (so they are visible in Talker error console, with stack trace)

---

## Extended example

```dart
import 'package:cherrypick/cherrypick.dart';
import 'package:talker/talker.dart';
import 'package:talker_cherrypick_logger/talker_cherrypick_logger.dart';

void main() {
  final talker = Talker();
  final observer = TalkerCherryPickObserver(talker);

  // Optionally: customize Talker output or filtering
  // talker.settings.logLevel = TalkerLogLevel.debug;

  CherryPick.openRootScope(observer: observer);

  // ...setup your DI modules as usual
  // All container events will appear in Talker logs for easy debugging!
}
```

---

## Additional information

- This package is especially useful for debugging large or layered projects using CherryPick.
- For advanced Talker configurations (UI, outputs to remote, filtering), see the [Talker documentation](https://pub.dev/packages/talker).
- This package does **not** interfere with DI graph construction or your app's behavior — it's purely diagnostic.
- For questions or issues, open an issue on the main [cherrypick repository](https://github.com/pese-dot-work/cherrypick).

---

## Contributing

Feel free to contribute improvements or report bugs via pull requests or issues!

---

## License

See [LICENSE](LICENSE) for details.
