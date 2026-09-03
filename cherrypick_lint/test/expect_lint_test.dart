import 'dart:io';

import 'package:test/test.dart';

/// `custom_lint` has its own testing mechanism: fixture files under
/// `example/lib` assert the exact diagnostics they expect via
/// `// expect_lint: <code>` comments (one file per rule group — await-rules,
/// annotation-rules, runtime-trap-rules). Running `dart run custom_lint`
/// over `example/` fails if any expected lint is missing, or if any
/// unexpected lint fires — so a clean exit code is the test.
///
/// See https://github.com/invertase/dart_custom_lint#testing-your-plugins.
void main() {
  test(
    'every // expect_lint clause in example/lib is fulfilled',
    () async {
      final result = await Process.run('dart', [
        'run',
        'custom_lint',
      ], workingDirectory: 'example');

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
