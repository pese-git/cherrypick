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

  test(
    'AddAwaitFix is safe on the PR #40 review scenarios',
    () async {
      // A disposable, untracked scratch file — never the committed fixture.
      // `--fix` mutates whatever it's pointed at, and a stray custom_lint
      // process from a previous run can keep writing to a file even after
      // this test's own process has exited (we've hit this firsthand); a
      // throwaway file limits the blast radius of that to "delete it",
      // instead of risking corruption of tracked source.
      final scratchFile = File('example/lib/_add_await_fix_scratch.dart');
      // Defensive: clean up a leftover from a previous run that crashed
      // before reaching its own cleanup below.
      if (scratchFile.existsSync()) scratchFile.deleteSync();

      // No `// expect_lint:` here on purpose — that comment suppresses the
      // diagnostic the same way `// ignore:` does, so `--fix` would never
      // see anything to act on.
      scratchFile.writeAsStringSync('''
import 'dart:async';

import 'package:cherrypick/cherrypick.dart';

void disposeScopeSync(Scope scope) {
  scope.dispose();
}

Future<void> batchCloseSubScopes(Scope child) async {
  await Future.wait([child.closeSubScope('1'), child.closeSubScope('2')]);
}
''');

      try {
        final result = await Process.run('dart', [
          'run',
          'custom_lint',
          '--fix',
        ], workingDirectory: 'example');
        expect(
          result.exitCode,
          anyOf(0, 1),
          reason:
              'custom_lint --fix itself crashed: '
              '${result.stdout}\n${result.stderr}',
        );

        final fixed = scratchFile.readAsStringSync();

        // A call inside a non-async function must be left alone: inserting
        // `await` there would be a compile error.
        expect(
          fixed,
          contains(
            'void disposeScopeSync(Scope scope) {\n  scope.dispose();\n}',
          ),
          reason: 'AddAwaitFix must not insert await outside an async context',
        );

        // Both closeSubScope calls sit inside Future.wait([...]) — the fix
        // must add await to each of them individually, and must never touch
        // the outer Future.wait(...) call itself (its range merely contains
        // theirs, it isn't the flagged node).
        expect(
          fixed,
          contains(
            'await Future.wait(['
            "await child.closeSubScope('1'), "
            "await child.closeSubScope('2')"
            ']);',
          ),
          reason:
              'AddAwaitFix must edit only the exact flagged node, not any '
              'invocation whose range merely contains it',
        );
      } finally {
        if (scratchFile.existsSync()) scratchFile.deleteSync();
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
