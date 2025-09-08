//
// Copyright 2021 Sergey Penkovsky (sergey.penkovsky@gmail.com)
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//      https://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import 'package:test/test.dart';
import 'package:build_test/build_test.dart';
import 'package:build/build.dart';

import 'package:cherrypick_generator/module_generator.dart';
import 'package:source_gen/source_gen.dart';

void main() {
  group('ModuleGenerator Tests', () {
    setUp(() {
      // ModuleGenerator setup if needed
    });

    group('Simple Module Generation', () {
      test('should generate basic module with instance binding', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';
import 'package:cherrypick/cherrypick.dart';

part 'test_module.module.cherrypick.g.dart';

@module()
abstract class TestModule extends Module {
  @instance()
  String testString() => "Hello World";
}
''';

        const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_module.dart';

// **************************************************************************
// ModuleGenerator
// **************************************************************************

final class \$TestModule extends TestModule {
  @override
  void builder(Scope currentScope) {
    bind<String>().toInstance(testString());
  }
}
''';

        await _testGeneration(input, expectedOutput);
      });

      test('should generate basic module with provide binding', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';
import 'package:cherrypick/cherrypick.dart';

part 'test_module.module.cherrypick.g.dart';

@module()
abstract class TestModule extends Module {
  @provide()
  String testString() => "Hello World";
}
''';

        const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_module.dart';

// **************************************************************************
// ModuleGenerator
// **************************************************************************

final class \$TestModule extends TestModule {
  @override
  void builder(Scope currentScope) {
    bind<String>().toProvide(() => testString());
  }
}
''';

        await _testGeneration(input, expectedOutput);
      });
    });

    group('Singleton Bindings', () {
      test('should generate singleton instance binding', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';
import 'package:cherrypick/cherrypick.dart';

part 'test_module.module.cherrypick.g.dart';

@module()
abstract class TestModule extends Module {
  @instance()
  @singleton()
  String testString() => "Hello World";
}
''';

        const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_module.dart';

// **************************************************************************
// ModuleGenerator
// **************************************************************************

final class \$TestModule extends TestModule {
  @override
  void builder(Scope currentScope) {
    bind<String>().toInstance(testString()).singleton();
  }
}
''';

        await _testGeneration(input, expectedOutput);
      });

      test('should generate singleton provide binding', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';
import 'package:cherrypick/cherrypick.dart';

part 'test_module.module.cherrypick.g.dart';

@module()
abstract class TestModule extends Module {
  @provide()
  @singleton()
  String testString() => "Hello World";
}
''';

        const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_module.dart';

// **************************************************************************
// ModuleGenerator
// **************************************************************************

final class \$TestModule extends TestModule {
  @override
  void builder(Scope currentScope) {
    bind<String>().toProvide(() => testString()).singleton();
  }
}
''';

        await _testGeneration(input, expectedOutput);
      });
    });

    group('Named Bindings', () {
      test('should generate named instance binding', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';
import 'package:cherrypick/cherrypick.dart';

part 'test_module.module.cherrypick.g.dart';

@module()
abstract class TestModule extends Module {
  @instance()
  @named('testName')
  String testString() => "Hello World";
}
''';

        const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_module.dart';

// **************************************************************************
// ModuleGenerator
// **************************************************************************

final class \$TestModule extends TestModule {
  @override
  void builder(Scope currentScope) {
    bind<String>().toInstance(testString()).withName('testName');
  }
}
''';

        await _testGeneration(input, expectedOutput);
      });

      test('should generate named singleton binding', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';
import 'package:cherrypick/cherrypick.dart';

part 'test_module.module.cherrypick.g.dart';

@module()
abstract class TestModule extends Module {
  @provide()
  @singleton()
  @named('testName')
  String testString() => "Hello World";
}
''';

        const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_module.dart';

// **************************************************************************
// ModuleGenerator
// **************************************************************************

final class \$TestModule extends TestModule {
  @override
  void builder(Scope currentScope) {
    bind<String>()
        .toProvide(() => testString())
        .withName('testName')
        .singleton();
  }
}
''';

        await _testGeneration(input, expectedOutput);
      });
    });

    group('Async Bindings', () {
      test('should generate async instance binding', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';
import 'package:cherrypick/cherrypick.dart';

part 'test_module.module.cherrypick.g.dart';

@module()
abstract class TestModule extends Module {
  @instance()
  Future<String> testString() async => "Hello World";
}
''';

        const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_module.dart';

// **************************************************************************
// ModuleGenerator
// **************************************************************************

final class \$TestModule extends TestModule {
  @override
  void builder(Scope currentScope) {
    bind<String>().toInstanceAsync(testString());
  }
}
''';

        await _testGeneration(input, expectedOutput);
      });

      test('should generate async provide binding', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';
import 'package:cherrypick/cherrypick.dart';

part 'test_module.module.cherrypick.g.dart';

@module()
abstract class TestModule extends Module {
  @provide()
  Future<String> testString() async => "Hello World";
}
''';

        const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_module.dart';

// **************************************************************************
// ModuleGenerator
// **************************************************************************

final class \$TestModule extends TestModule {
  @override
  void builder(Scope currentScope) {
    bind<String>().toProvideAsync(() => testString());
  }
}
''';

        await _testGeneration(input, expectedOutput);
      });

      test('should generate async binding with params', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';
import 'package:cherrypick/cherrypick.dart';

part 'test_module.module.cherrypick.g.dart';

@module()
abstract class TestModule extends Module {
  @provide()
  Future<String> testString(@params() dynamic params) async => "Hello \$params";
}
''';

        const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_module.dart';

// **************************************************************************
// ModuleGenerator
// **************************************************************************

final class \$TestModule extends TestModule {
  @override
  void builder(Scope currentScope) {
    bind<String>().toProvideAsyncWithParams((args) => testString(args));
  }
}
''';

        await _testGeneration(input, expectedOutput);
      });
    });

    group('Dependencies Injection', () {
      test('should generate binding with injected dependencies', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';
import 'package:cherrypick/cherrypick.dart';

part 'test_module.module.cherrypick.g.dart';

class ApiClient {}
class Repository {}

@module()
abstract class TestModule extends Module {
  @provide()
  Repository repository(ApiClient client) => Repository();
}
''';

        const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_module.dart';

// **************************************************************************
// ModuleGenerator
// **************************************************************************

final class \$TestModule extends TestModule {
  @override
  void builder(Scope currentScope) {
    bind<Repository>().toProvide(
      () => repository(currentScope.resolve<ApiClient>()),
    );
  }
}
''';

        await _testGeneration(input, expectedOutput);
      });

      test('should generate binding with named dependencies', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';
import 'package:cherrypick/cherrypick.dart';

part 'test_module.module.cherrypick.g.dart';

class ApiClient {}
class Repository {}

@module()
abstract class TestModule extends Module {
  @provide()
  Repository repository(@named('api') ApiClient client) => Repository();
}
''';

        const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_module.dart';

// **************************************************************************
// ModuleGenerator
// **************************************************************************

final class \$TestModule extends TestModule {
  @override
  void builder(Scope currentScope) {
    bind<Repository>().toProvide(
      () => repository(currentScope.resolve<ApiClient>(named: 'api')),
    );
  }
}
''';

        await _testGeneration(input, expectedOutput);
      });
    });

    group('Runtime Parameters', () {
      test('should generate binding with params', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';
import 'package:cherrypick/cherrypick.dart';

part 'test_module.module.cherrypick.g.dart';

@module()
abstract class TestModule extends Module {
  @provide()
  String testString(@params() dynamic params) => "Hello \$params";
}
''';

        const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_module.dart';

// **************************************************************************
// ModuleGenerator
// **************************************************************************

final class \$TestModule extends TestModule {
  @override
  void builder(Scope currentScope) {
    bind<String>().toProvideWithParams((args) => testString(args));
  }
}
''';

        await _testGeneration(input, expectedOutput);
      });

      test('should generate async binding with params', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';
import 'package:cherrypick/cherrypick.dart';

part 'test_module.module.cherrypick.g.dart';

@module()
abstract class TestModule extends Module {
  @provide()
  Future<String> testString(@params() dynamic params) async => "Hello \$params";
}
''';

        const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_module.dart';

// **************************************************************************
// ModuleGenerator
// **************************************************************************

final class \$TestModule extends TestModule {
  @override
  void builder(Scope currentScope) {
    bind<String>().toProvideAsyncWithParams((args) => testString(args));
  }
}
''';

        await _testGeneration(input, expectedOutput);
      });
    });

    group('Complex Scenarios', () {
      test('should generate module with multiple bindings', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';
import 'package:cherrypick/cherrypick.dart';

part 'test_module.module.cherrypick.g.dart';

class ApiClient {}
class Repository {}

@module()
abstract class TestModule extends Module {
  @instance()
  @singleton()
  @named('baseUrl')
  String baseUrl() => "https://api.example.com";

  @provide()
  @singleton()
  ApiClient apiClient(@named('baseUrl') String url) => ApiClient();

  @provide()
  Repository repository(ApiClient client) => Repository();

  @provide()
  @named('greeting')
  String greeting(@params() dynamic name) => "Hello \$name";
}
''';

        const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_module.dart';

// **************************************************************************
// ModuleGenerator
// **************************************************************************

final class \$TestModule extends TestModule {
  @override
  void builder(Scope currentScope) {
    bind<String>().toInstance(baseUrl()).withName('baseUrl').singleton();
    bind<ApiClient>()
        .toProvide(
          () => apiClient(currentScope.resolve<String>(named: 'baseUrl')),
        )
        .singleton();
    bind<Repository>().toProvide(
      () => repository(currentScope.resolve<ApiClient>()),
    );
    bind<String>()
        .toProvideWithParams((args) => greeting(args))
        .withName('greeting');
  }
}
''';

        await _testGeneration(input, expectedOutput);
      });
    });

    group('Error Cases', () {
      test('should throw error for non-class element', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

part 'test_module.module.cherrypick.g.dart';

@module()
void notAClass() {}
''';

        await expectLater(
          () => _testGeneration(input, ''),
          throwsA(isA<InvalidGenerationSourceError>()),
        );
      });

      test('should throw error for method without @instance or @provide',
          () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';
import 'package:cherrypick/cherrypick.dart';

part 'test_module.module.cherrypick.g.dart';

@module()
abstract class TestModule extends Module {
  String testString() => "Hello World";
}
''';

        await expectLater(
          () => _testGeneration(input, ''),
          throwsA(isA<InvalidGenerationSourceError>()),
        );
      });

      test('should throw error for @params with @instance', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';
import 'package:cherrypick/cherrypick.dart';

part 'test_module.module.cherrypick.g.dart';

@module()
abstract class TestModule extends Module {
  @instance()
  String testString(@params() dynamic params) => "Hello \$params";
}
''';

        await expectLater(
          () => _testGeneration(input, ''),
          throwsA(isA<InvalidGenerationSourceError>()),
        );
      });
    });
  });
}

/// Helper function to test code generation
Future<void> _testGeneration(String input, String expectedOutput) async {
  await testBuilder(
    moduleBuilder(BuilderOptions.empty),
    {
      'a|lib/test_module.dart': input,
    },
    outputs: {
      'a|lib/test_module.module.cherrypick.g.dart': expectedOutput,
    },
    reader: await PackageAssetReader.currentIsolate(),
  );
}
