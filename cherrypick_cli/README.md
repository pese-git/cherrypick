# CherryPick CLI

A command-line tool for managing and generating `build.yaml` configuration for the [CherryPick](https://github.com/pese-git/cherrypick) dependency injection ecosystem for Dart & Flutter.

---

## Features
- 📦 Quickly add or update CherryPick generator sections in your project's `build.yaml`.
- 🛡️ Safely preserves unrelated configs and packages.
- 📝 Always outputs a human-friendly, formatted YAML file.
- 🏷️ Supports custom output directories and custom build.yaml file paths.

---

## Getting Started

1. **Navigate to the CLI package directory:**
   ```bash
   cd cherrypick_cli
   ```
2. **Get dependencies:**
   ```bash
   dart pub get
   ```
3. **Run the CLI:**
   ```bash
   dart run cherrypick_cli init --output_dir=lib/generated
   ```

---

## Usage

### Show help
```bash
dart run cherrypick_cli --help
```

### Add or update CherryPick sections in build.yaml
```bash
dart run cherrypick_cli init --output_dir=lib/generated
```

#### Options:
- `--output_dir`, `-o`  — Directory for generated code (default: `lib/generated`)
- `--build_yaml`, `-f`  — Path to build.yaml file (default: `build.yaml`)

#### Example with custom build.yaml
```bash
dart run cherrypick_cli init --output_dir=custom/dir --build_yaml=custom_build.yaml
```

---

## What does it do?
- Adds or updates the following sections in your `build.yaml` (or custom file):
  - `cherrypick_generator|inject_generator`
  - `cherrypick_generator|module_generator`
- Ensures all YAML is pretty-printed and readable.
- Leaves unrelated configs untouched.

---

## Example Output
```yaml
targets:
  $default:
    builders:
      cherrypick_generator|inject_generator:
        options:
          build_extensions:
            ^lib/{{}}.dart:
              - lib/generated/{{}}.inject.cherrypick.g.dart
          output_dir: lib/generated
        generate_for:
          - lib/**.dart
      cherrypick_generator|module_generator:
        options:
          build_extensions:
            ^lib/di/{{}}.dart:
              - lib/generated/di/{{}}.module.cherrypick.g.dart
          output_dir: lib/generated
        generate_for:
          - lib/**.dart
```

---

## Contributing
Pull requests and issues are welcome! See the [main CherryPick repo](https://github.com/pese-git/cherrypick) for more.

## License
See [LICENSE](LICENSE).
