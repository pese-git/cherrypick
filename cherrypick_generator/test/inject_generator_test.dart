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

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:cherrypick_generator/inject_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

void main() {
  group('InjectGenerator Tests', () {
    setUp(() {
      // InjectGenerator setup if needed
    });

    group('Basic Injection', () {
      test('should generate mixin for simple injection', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

part 'test_widget.inject.cherrypick.g.dart';

class MyService {}

@injectable()
class TestWidget {
  @inject()
  late final MyService service;
}
''';

        const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_widget.dart';

// **************************************************************************
// InjectGenerator
// **************************************************************************

mixin _\$TestWidget {
  void _inject(TestWidget instance) {
    instance.service = CherryPick.openRootScope().resolve<MyService>();
  }
}
''';

        await _testGeneration(input, expectedOutput);
      });

      test('should generate mixin for nullable injection', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

part 'test_widget.inject.cherrypick.g.dart';

class MyService {}

@injectable()
class TestWidget {
  @inject()
  late final MyService? service;
}
''';

        const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_widget.dart';

// **************************************************************************
// InjectGenerator
// **************************************************************************

mixin _\$TestWidget {
  void _inject(TestWidget instance) {
    instance.service = CherryPick.openRootScope().tryResolve<MyService>();
  }
}
''';

        await _testGeneration(input, expectedOutput);
      });
    });

    group('Named Injection', () {
      test('should generate mixin for named injection', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

part 'test_widget.inject.cherrypick.g.dart';

class MyService {}

@injectable()
class TestWidget {
  @inject()
  @named('myService')
  late final MyService service;
}
''';

        const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_widget.dart';

// **************************************************************************
// InjectGenerator
// **************************************************************************

mixin _\$TestWidget {
  void _inject(TestWidget instance) {
    instance.service = CherryPick.openRootScope().resolve<MyService>(
      named: 'myService',
    );
  }
}
''';

        await _testGeneration(input, expectedOutput);
      });

      test('should generate mixin for named nullable injection', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

part 'test_widget.inject.cherrypick.g.dart';

class MyService {}

@injectable()
class TestWidget {
  @inject()
  @named('myService')
  late final MyService? service;
}
''';

        const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_widget.dart';

// **************************************************************************
// InjectGenerator
// **************************************************************************

mixin _\$TestWidget {
  void _inject(TestWidget instance) {
    instance.service = CherryPick.openRootScope().tryResolve<MyService>(
      named: 'myService',
    );
  }
}
''';

        await _testGeneration(input, expectedOutput);
      });
    });

    group('Scoped Injection', () {
      test('should generate mixin for scoped injection', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

part 'test_widget.inject.cherrypick.g.dart';

class MyService {}

@injectable()
class TestWidget {
  @inject()
  @scope('userScope')
  late final MyService service;
}
''';

        const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_widget.dart';

// **************************************************************************
// InjectGenerator
// **************************************************************************

mixin _\$TestWidget {
  void _inject(TestWidget instance) {
    instance.service =
        CherryPick.openScope(scopeName: 'userScope').resolve<MyService>();
  }
}
''';

        await _testGeneration(input, expectedOutput);
      });

      test('should generate mixin for scoped named injection', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

part 'test_widget.inject.cherrypick.g.dart';

class MyService {}

@injectable()
class TestWidget {
  @inject()
  @scope('userScope')
  @named('myService')
  late final MyService service;
}
''';

        const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_widget.dart';

// **************************************************************************
// InjectGenerator
// **************************************************************************

mixin _\$TestWidget {
  void _inject(TestWidget instance) {
    instance.service = CherryPick.openScope(
      scopeName: 'userScope',
    ).resolve<MyService>(named: 'myService');
  }
}
''';

        await _testGeneration(input, expectedOutput);
      });
    });

    group('Async Injection', () {
      test('should generate mixin for Future injection', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

part 'test_widget.inject.cherrypick.g.dart';

class MyService {}

@injectable()
class TestWidget {
  @inject()
  late final Future<MyService> service;
}
''';

        const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_widget.dart';

// **************************************************************************
// InjectGenerator
// **************************************************************************

mixin _\$TestWidget {
  void _inject(TestWidget instance) {
    instance.service = CherryPick.openRootScope().resolveAsync<MyService>();
  }
}
''';

        await _testGeneration(input, expectedOutput);
      });

      test('should generate mixin for nullable Future injection', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

part 'test_widget.inject.cherrypick.g.dart';

class MyService {}

@injectable()
class TestWidget {
  @inject()
  late final Future<MyService?> service;
}
''';

        const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_widget.dart';

// **************************************************************************
// InjectGenerator
// **************************************************************************

mixin _\$TestWidget {
  void _inject(TestWidget instance) {
    instance.service = CherryPick.openRootScope().tryResolveAsync<MyService>();
  }
}
''';

        await _testGeneration(input, expectedOutput);
      });

      test('should generate mixin for named Future injection', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

part 'test_widget.inject.cherrypick.g.dart';

class MyService {}

@injectable()
class TestWidget {
  @inject()
  @named('myService')
  late final Future<MyService> service;
}
''';

        const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_widget.dart';

// **************************************************************************
// InjectGenerator
// **************************************************************************

mixin _\$TestWidget {
  void _inject(TestWidget instance) {
    instance.service = CherryPick.openRootScope().resolveAsync<MyService>(
      named: 'myService',
    );
  }
}
''';

        await _testGeneration(input, expectedOutput);
      });
    });

    group('Multiple Fields', () {
      test('should generate mixin for multiple injected fields', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

part 'test_widget.inject.cherrypick.g.dart';

class ApiService {}
class DatabaseService {}
class CacheService {}

@injectable()
class TestWidget {
  @inject()
  late final ApiService apiService;

  @inject()
  @named('cache')
  late final CacheService? cacheService;

  @inject()
  @scope('dbScope')
  late final Future<DatabaseService> dbService;

  // Non-injected field should be ignored
  String nonInjectedField = "test";
}
''';

        const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_widget.dart';

// **************************************************************************
// InjectGenerator
// **************************************************************************

mixin _\$TestWidget {
  void _inject(TestWidget instance) {
    instance.apiService = CherryPick.openRootScope().resolve<ApiService>();
    instance.cacheService = CherryPick.openRootScope().tryResolve<CacheService>(
      named: 'cache',
    );
    instance.dbService =
        CherryPick.openScope(
          scopeName: 'dbScope',
        ).resolveAsync<DatabaseService>();
  }
}
''';

        await _testGeneration(input, expectedOutput);
      });
    });

    group('Complex Types', () {
      test('should handle generic types', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

part 'test_widget.inject.cherrypick.g.dart';

@injectable()
class TestWidget {
  @inject()
  late final List<String> stringList;

  @inject()
  late final Map<String, int> stringIntMap;

  @inject()
  late final Future<List<String>> futureStringList;
}
''';

        const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_widget.dart';

// **************************************************************************
// InjectGenerator
// **************************************************************************

mixin _\$TestWidget {
  void _inject(TestWidget instance) {
    instance.stringList = CherryPick.openRootScope().resolve<List<String>>();
    instance.stringIntMap =
        CherryPick.openRootScope().resolve<Map<String, int>>();
    instance.futureStringList =
        CherryPick.openRootScope().resolveAsync<List<String>>();
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

part 'test_widget.inject.cherrypick.g.dart';

@injectable()
void notAClass() {}
''';

        await expectLater(
          () => _testGeneration(input, ''),
          throwsA(isA<InvalidGenerationSourceError>()),
        );
      });

      test(
        'should generate empty mixin for class without @inject fields',
        () async {
          const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

part 'test_widget.inject.cherrypick.g.dart';

@injectable()
class TestWidget {
  String normalField = "test";
  int anotherField = 42;
}
''';

          const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_widget.dart';

// **************************************************************************
// InjectGenerator
// **************************************************************************

mixin _\$TestWidget {
  void _inject(TestWidget instance) {}
}
''';

          await _testGeneration(input, expectedOutput);
        },
      );
    });

    group('Edge Cases', () {
      test('should handle empty scope name', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

part 'test_widget.inject.cherrypick.g.dart';

class MyService {}

@injectable()
class TestWidget {
  @inject()
  @scope('')
  late final MyService service;
}
''';

        const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_widget.dart';

// **************************************************************************
// InjectGenerator
// **************************************************************************

mixin _\$TestWidget {
  void _inject(TestWidget instance) {
    instance.service = CherryPick.openRootScope().resolve<MyService>();
  }
}
''';

        await _testGeneration(input, expectedOutput);
      });

      test('should handle empty named value', () async {
        const input = '''
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

part 'test_widget.inject.cherrypick.g.dart';

class MyService {}

@injectable()
class TestWidget {
  @inject()
  @named('')
  late final MyService service;
}
''';

        const expectedOutput = '''
// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_widget.dart';

// **************************************************************************
// InjectGenerator
// **************************************************************************

mixin _\$TestWidget {
  void _inject(TestWidget instance) {
    instance.service = CherryPick.openRootScope().resolve<MyService>();
  }
}
''';

        await _testGeneration(input, expectedOutput);
      });
    });
  });
}

/// Helper function to test code generation
Future<void> _testGeneration(String input, String expectedOutput) async {
  await testBuilder(
    injectBuilder(BuilderOptions.empty),
    {'a|lib/test_widget.dart': input},
    outputs: {'a|lib/test_widget.inject.cherrypick.g.dart': expectedOutput},
    readerWriter: TestReaderWriter(),
  );
}
