---
sidebar_position: 5
---

# Using Annotations & Code Generation

CherryPick provides best-in-class developer ergonomics and type safety through **Dart annotations** and code generation. This lets you dramatically reduce boilerplate: simply annotate your classes, fields, and modules, run the code generator, and enjoy auto-wired dependency injection!

## How It Works

1. **Annotate** your services, providers, and fields using `cherrypick_annotations`.
2. **Generate** code using `cherrypick_generator` with `build_runner`.
3. **Use** generated modules and mixins for fully automated DI (dependency injection).

---

## Supported Annotations

| Annotation        | Target         | Description                                                                    |
|-------------------|---------------|--------------------------------------------------------------------------------|
| `@injectable()`   | class         | Enables automatic field injection for this class (mixin will be generated)      |
| `@inject()`       | field         | Field will be injected using DI (works with @injectable classes)                |
| `@module()`       | class         | Declares a DI module; its methods can provide services/providers                |
| `@provide`        | method        | Registers as a DI provider method (may have dependencies as parameters)         |
| `@instance`       | method/class  | Registers an instance (new object on each resolution, i.e. factory)             |
| `@singleton`      | method/class  | Registers as a singleton (one instance per scope)                               |
| `@named`          | field/param   | Use named instance (bind/resolve by name or apply to field/param)               |
| `@scope`          | field/param   | Inject or resolve from a specific named scope                                   |
| `@params`         | param         | Marks method parameter as filled by user-supplied runtime params at resolution  |

You can easily **combine** these annotations for advanced scenarios!

---

## Field Injection Example

```dart
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@injectable()
class ProfilePage with _\$ProfilePage {
  @inject()
  late final AuthService auth;

  @inject()
  @scope('profile')
  late final ProfileManager manager;

  @inject()
  @named('admin')
  late final UserService adminUserService;
}
```

- After running build_runner, the mixin `_ProfilePage` will be generated for field injection.
- Call `myProfilePage.injectFields();` or use the mixin's auto-inject feature, and all dependencies will be set up for you.

## Module and Provider Example

```dart
@module()
abstract class AppModule {
  @singleton
  AuthService provideAuth(Api api) => AuthService(api);

  @named('logging')
  @provide
  Future<Logger> provideLogger(@params Map<String, dynamic> args) async => ...;
}
```

- Mark class as `@module`, write provider methods.
- Use `@singleton`, `@named`, `@provide`, `@params` to control lifecycle, key names, and parameters.
- The generator will produce a class like `$AppModule` with the proper DI bindings.

## Usage Steps

1. **Add to your pubspec.yaml**:

   ```yaml
   dependencies:
     cherrypick: any
     cherrypick_annotations: any

   dev_dependencies:
     cherrypick_generator: any
     build_runner: any
   ```

2. **Annotate** your classes and modules as above.

3. **Run code generation:**

   ```shell
   dart run build_runner build --delete-conflicting-outputs
   # or in Flutter:
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Register modules and use auto-injection:**

   ```dart
   final scope = CherryPick.openRootScope()
     ..installModules([\$AppModule()]);

   final profile = ProfilePage();
   profile.injectFields(); // injects all @inject fields
   ```

## Advanced: Parameters, Named Instances, and Scopes

- Use `@named` for key-based multi-implementation injection.
- Use `@scope` when dependencies live in a non-root scope.
- Use `@params` for runtime arguments passed during resolution.

---

## Troubleshooting & Tips

- After modifying DI-related code, always re-run `build_runner`.
- Do not manually edit `.g.dart` files—let the generator manage them.
- Errors in annotation usage (e.g., using `@singleton` on wrong target) are shown at build time.

---

## References

<!--
- [Full annotation reference (en)](doc/annotations_en.md)
- [cherrypick_annotations/README.md](../cherrypick_annotations/README.md)
- [cherrypick_generator/README.md](../cherrypick_generator/README.md)
- See the [`examples/postly`](../examples/postly) for a full working DI+annotations app.
-->
