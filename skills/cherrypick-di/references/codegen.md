# CherryPick code generation (4.x)

## Setup

```yaml
dependencies:
  cherrypick: ^4.0.0
  cherrypick_annotations: ^4.0.0
dev_dependencies:
  build_runner: ^2.5.0
  cherrypick_generator: ^4.0.0
```

```sh
dart run build_runner build      # or: dart run build_runner watch
```

The builders run on `lib/**.dart` only. Generated files are parts:
`<file>.module.cherrypick.g.dart` and `<file>.inject.cherrypick.g.dart`.
Do not edit them, and follow the project's convention for committing them
(many projects git-ignore `*.g.dart`). Recent `build_runner` versions ignore
`--delete-conflicting-outputs`; it is harmless to pass.

All annotations are classes: write `@module()`, `@provide()`, `@instance()`,
`@singleton()`, `@named('id')`, `@params()`, `@injectable()`, `@inject()`,
`@scope('path')` — always with parentheses.

## Modules: `@module`

```dart
import 'package:cherrypick/cherrypick.dart';
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

part 'app_module.module.cherrypick.g.dart';

@module()
abstract class AppModule extends Module {
  @instance()
  @named('baseUrl')
  String baseUrl() => 'https://api.example.com';

  @provide()
  @singleton()
  ApiClient api(@named('baseUrl') String url) => ApiClient(url);

  @provide()
  UserRepository repo(ApiClient api) => UserRepository(api);

  @provide()
  @singleton()
  Future<Database> db() async => Database.open();

  @provide()
  UserCubit userCubit(UserRepository repo, @params() dynamic userId) =>
      UserCubit(repo, userId as String);
}
```

What the generator emits for that module (verified with 4.0.0):

```dart
final class $AppModule extends AppModule {
  @override
  void builder(Scope currentScope) {
    bind<String>().toInstance(baseUrl()).withName('baseUrl');
    bind<ApiClient>()
        .toProvide(() => api(currentScope.resolve<String>(named: 'baseUrl')))
        .singleton();
    bind<UserRepository>().toProvide(() => repo(currentScope.resolve<ApiClient>()));
    bind<Database>().toProvideAsync(() => db()).singleton();
    bind<UserCubit>().toProvideWithParams(
        (args) => userCubit(currentScope.resolve<UserRepository>(), args));
  }
}
```

So:

- Install the generated class: `scope.installModules([$AppModule()])`.
- Method parameters become `currentScope.resolve<T>()` calls, evaluated lazily
  inside the provider; `@named('x')` on a parameter adds `named: 'x'`.
- A method returning `Future<T>` binds `T` with `toProvideAsync` — resolve it
  with `resolveAsync<T>()`, not `resolve<Future<T>>()`.
- `@params()` marks the runtime argument; it requires `@provide()` and maps to
  `toProvideWithParams` / `toProvideAsyncWithParams`.
- `@instance()` → `toInstance(method())`, evaluated at install time.
- `@singleton()` → `.singleton()`.

Rules the generator enforces (it fails the build, or silently emits nothing):

| Mistake | Result |
|---|---|
| no `part '<file>.module.cherrypick.g.dart';` | build succeeds, **nothing generated** (only a log warning) |
| class does not `extends Module` | generated part does not compile |
| class is not `abstract` | dead end: either `builder` is missing or it is a method without `@provide`/`@instance` |
| any method (private and `static` too) without `@provide()` or `@instance()` | build error; getters/setters are exempt |
| both `@provide()` and `@instance()` | build error |
| `@params()` without `@provide()` | build error |
| `@singleton()` on a `void` method | build error |
| `@named('')`, or a value that is not an identifier (`'my-api'`) | build error: must match `^[a-zA-Z_][a-zA-Z0-9_]*$` |

## Field injection: `@injectable` / `@inject`

```dart
import 'package:cherrypick/cherrypick.dart';
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

part 'profile_screen.inject.cherrypick.g.dart';

@injectable()
class ProfileController with _$ProfileController {
  @inject()
  late final UserRepository repo;

  @inject()
  @named('baseUrl')
  late final String baseUrl;

  @inject()
  @scope('profile')
  late final ProfileManager manager;

  @inject()
  late final Future<Database> db;   // resolveAsync

  @inject()
  late final Analytics? analytics;  // tryResolve — null if not bound

  ProfileController() {
    _inject(this);
  }
}
```

The generated mixin `_$ProfileController` has one method, `void _inject(ProfileController instance)`:

```dart
instance.repo = CherryPick.openRootScope().resolve<UserRepository>();
instance.baseUrl = CherryPick.openRootScope().resolve<String>(named: 'baseUrl');
instance.manager = CherryPick.openScope(scopeName: 'profile').resolve<ProfileManager>();
instance.db = CherryPick.openRootScope().resolveAsync<Database>();
instance.analytics = CherryPick.openRootScope().tryResolve<Analytics>();
```

Consequences:

- Call `_inject(this)` yourself (constructor, `initState`, …). There is no
  `injectFields()` method, whatever older docs say.
- Injection always goes through the global tree (`openRootScope` /
  `openScope(scopeName:)`). It cannot target a scope object you hold locally.
- `@scope('profile')` calls `CherryPick.openScope`, which **creates** the
  subscope if it is missing — install its modules before injecting, or the
  resolve fails on an empty new scope.
- Fields must be `late final` (the generator rejects non-final fields; `cherrypick_lint` flags non-`late final`).
- Nullable field type ⇒ `tryResolve`; `Future<T>` ⇒ `resolveAsync`.

## Mixing styles

Generated and hand-written modules are interchangeable: install them together,
e.g. `installModules([CoreModule(talker: talker), $AppModule()])`. Use a
hand-written module when a binding needs constructor arguments of the module
itself or logic codegen cannot express.
