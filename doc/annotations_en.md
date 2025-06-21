# DI Code Generation with Annotations (CherryPick)

CherryPick enables smart, fully-automated dependency injection (DI) for Dart/Flutter via annotations and code generation.
This eliminates boilerplate and guarantees correctness—just annotate, run the generator, and use!

---

## 1. How does it work?

You annotate classes, fields, and modules using [cherrypick_annotations].  
The [cherrypick_generator] processes these, generating code that registers your dependencies and wires up fields or modules.

You then run:
```sh
dart run build_runner build --delete-conflicting-outputs
```
— and use the generated files in your app.

---

## 2. Supported Annotations

| Annotation        | Where           | Purpose                                                  |
|-------------------|-----------------|----------------------------------------------------------|
| `@injectable()`   | class           | Enables auto field injection; mixin will be generated    |
| `@inject()`       | field           | Field will be injected automatically                     |
| `@scope()`        | field/param     | Use a named scope when resolving this dep                |
| `@named()`        | field/param     | Bind/resolve a named interface implementation            |
| `@module()`       | class           | Marks as a DI module (methods = providers)               |
| `@provide`        | method          | Registers a type via this provider method                |
| `@instance`       | method          | Registers a direct instance (like singleton/factory)     |
| `@singleton`      | method/class    | The target is a singleton                                |
| `@params`         | param           | Accepts runtime/constructor params for providers         |

**You can combine annotations as needed for advanced use-cases.**

---

## 3. Practical Examples

### A. Field Injection (recommended for widgets/classes)

```dart
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@injectable()
class MyWidget with _$MyWidget { // the generated mixin
  @inject()
  late final AuthService auth;

  @inject()
  @scope('profile')
  late final ProfileManager profile;

  @inject()
  @named('special')
  late final ApiClient specialApi;
}
```

- After running build_runner, the mixin _$MyWidget is created.
- Call `MyWidget().injectFields();` (method name may be `_inject` or similar) to populate the fields!

### B. Module Binding (recommended for global app services)

```dart
@module()
abstract class AppModule extends Module {
  @singleton
  AuthService provideAuth(Api api) => AuthService(api);

  @provide
  @named('logging')
  Future<Logger> provideLogger(@params Map<String, dynamic> args) async => ...
}
```

- Providers can return async(`Future<T>`) or sync.
- `@singleton` = one instance per scope.

---

## 4. Using the Generated Code

1. Add to your `pubspec.yaml`:

   ```yaml
   dependencies:
     cherrypick: any
     cherrypick_annotations: any

   dev_dependencies:
     cherrypick_generator: any
     build_runner: any
   ```

2. Import generated files (e.g. `app_module.module.cherrypick.g.dart`, `your_class.inject.cherrypick.g.dart`).

3. Register modules:

   ```dart
   final scope = openRootScope()
     ..installModules([$AppModule()]);
   ```

4. For classes with auto-injected fields, mix in the generated mixin and call the injector:

   ```dart
   final widget = MyWidget();
   widget.injectFields(); // or use the mixin's helper
   ```

5. All dependencies are now available and ready to use!

---

## 5. Advanced Features

- **Named and Scoped dependencies:** use `@named`, `@scope` on fields/methods and in resolve().
- **Async support:** Providers or injected fields can be Future<T> (resolveAsync).
- **Runtime parameters:** Decorate a parameter with `@params`, and use `resolve<T>(params: ...)`.
- **Combining strategies:** Mix field injection (`@injectable`) and module/provider (`@module` + methods) in one app.

---

## 6. Troubleshooting

- Make sure all dependencies are annotated, imports are correct, and run `build_runner` on every code/DI change.
- Errors in annotation usage (e.g. `@singleton` on non-class/method) will be shown at build time.
- Use the `.g.dart` files directly—do not edit them by hand.

---

## 7. References

- [Cherrypick Generator README (extended)](../cherrypick_generator/README.md)
- Example: `examples/postly`
- [API Reference](../cherrypick/doc/api/)

---
