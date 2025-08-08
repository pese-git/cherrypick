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

import 'package:cherrypick_generator/src/bind_spec.dart';
import 'package:test/test.dart';

void main() {
  group('BindSpec Tests', () {
    group('BindSpec Creation', () {
      test('should create BindSpec with all properties', () {
        final bindSpec = BindSpec(
          returnType: 'ApiClient',
          methodName: 'createApiClient',
          isSingleton: true,
          named: 'mainApi',
          parameters: [],
          bindingType: BindingType.provide,
          isAsyncInstance: false,
          isAsyncProvide: true,
          hasParams: false,
        );

        expect(bindSpec.returnType, equals('ApiClient'));
        expect(bindSpec.methodName, equals('createApiClient'));
        expect(bindSpec.isSingleton, isTrue);
        expect(bindSpec.named, equals('mainApi'));
        expect(bindSpec.parameters, isEmpty);
        expect(bindSpec.bindingType, equals(BindingType.provide));
        expect(bindSpec.isAsyncInstance, isFalse);
        expect(bindSpec.isAsyncProvide, isTrue);
        expect(bindSpec.hasParams, isFalse);
      });

      test('should create BindSpec with minimal properties', () {
        final bindSpec = BindSpec(
          returnType: 'String',
          methodName: 'getString',
          isSingleton: false,
          parameters: [],
          bindingType: BindingType.instance,
          isAsyncInstance: false,
          isAsyncProvide: false,
          hasParams: false,
        );

        expect(bindSpec.returnType, equals('String'));
        expect(bindSpec.methodName, equals('getString'));
        expect(bindSpec.isSingleton, isFalse);
        expect(bindSpec.named, isNull);
        expect(bindSpec.bindingType, equals(BindingType.instance));
      });
    });

    group('Bind Generation - Instance', () {
      test('should generate simple instance bind', () {
        final bindSpec = BindSpec(
          returnType: 'String',
          methodName: 'getString',
          isSingleton: false,
          parameters: [],
          bindingType: BindingType.instance,
          isAsyncInstance: false,
          isAsyncProvide: false,
          hasParams: false,
        );

        final result = bindSpec.generateBind(4);
        expect(result, equals('    bind<String>().toInstance(getString());'));
      });

      test('should generate singleton instance bind', () {
        final bindSpec = BindSpec(
          returnType: 'String',
          methodName: 'getString',
          isSingleton: true,
          parameters: [],
          bindingType: BindingType.instance,
          isAsyncInstance: false,
          isAsyncProvide: false,
          hasParams: false,
        );

        final result = bindSpec.generateBind(4);
        expect(result,
            equals('    bind<String>().toInstance(getString()).singleton();'));
      });

      test('should generate named instance bind', () {
        final bindSpec = BindSpec(
          returnType: 'String',
          methodName: 'getString',
          isSingleton: false,
          named: 'testString',
          parameters: [],
          bindingType: BindingType.instance,
          isAsyncInstance: false,
          isAsyncProvide: false,
          hasParams: false,
        );

        final result = bindSpec.generateBind(4);
        expect(
            result,
            equals(
                "    bind<String>().toInstance(getString()).withName('testString');"));
      });

      test('should generate named singleton instance bind', () {
        final bindSpec = BindSpec(
          returnType: 'String',
          methodName: 'getString',
          isSingleton: true,
          named: 'testString',
          parameters: [],
          bindingType: BindingType.instance,
          isAsyncInstance: false,
          isAsyncProvide: false,
          hasParams: false,
        );

        final result = bindSpec.generateBind(4);
        expect(
            result,
            equals(
                "    bind<String>().toInstance(getString()).withName('testString').singleton();"));
      });

      test('should generate async instance bind', () {
        final bindSpec = BindSpec(
          returnType: 'String',
          methodName: 'getString',
          isSingleton: false,
          parameters: [],
          bindingType: BindingType.instance,
          isAsyncInstance: true,
          isAsyncProvide: false,
          hasParams: false,
        );

        final result = bindSpec.generateBind(4);
        expect(
            result, equals('    bind<String>().toInstanceAsync(getString());'));
      });
    });

    group('Bind Generation - Provide', () {
      test('should generate simple provide bind', () {
        final bindSpec = BindSpec(
          returnType: 'String',
          methodName: 'getString',
          isSingleton: false,
          parameters: [],
          bindingType: BindingType.provide,
          isAsyncInstance: false,
          isAsyncProvide: false,
          hasParams: false,
        );

        final result = bindSpec.generateBind(4);
        expect(
            result, equals('    bind<String>().toProvide(() => getString());'));
      });

      test('should generate async provide bind', () {
        final bindSpec = BindSpec(
          returnType: 'String',
          methodName: 'getString',
          isSingleton: false,
          parameters: [],
          bindingType: BindingType.provide,
          isAsyncInstance: false,
          isAsyncProvide: true,
          hasParams: false,
        );

        final result = bindSpec.generateBind(4);
        expect(result,
            equals('    bind<String>().toProvideAsync(() => getString());'));
      });

      test('should generate provide bind with params', () {
        final bindSpec = BindSpec(
          returnType: 'String',
          methodName: 'getString',
          isSingleton: false,
          parameters: [],
          bindingType: BindingType.provide,
          isAsyncInstance: false,
          isAsyncProvide: false,
          hasParams: true,
        );

        final result = bindSpec.generateBind(4);
        expect(
            result,
            equals(
                '    bind<String>().toProvideWithParams((args) => getString());'));
      });

      test('should generate async provide bind with params', () {
        final bindSpec = BindSpec(
          returnType: 'String',
          methodName: 'getString',
          isSingleton: false,
          parameters: [],
          bindingType: BindingType.provide,
          isAsyncInstance: false,
          isAsyncProvide: true,
          hasParams: true,
        );

        final result = bindSpec.generateBind(4);
        expect(
            result,
            equals(
                '    bind<String>().toProvideAsyncWithParams((args) => getString());'));
      });
    });

    group('Complex Scenarios', () {
      test('should generate bind with all options', () {
        final bindSpec = BindSpec(
          returnType: 'ApiClient',
          methodName: 'createApiClient',
          isSingleton: true,
          named: 'mainApi',
          parameters: [],
          bindingType: BindingType.provide,
          isAsyncInstance: false,
          isAsyncProvide: true,
          hasParams: false,
        );

        final result = bindSpec.generateBind(4);
        expect(
            result,
            equals(
                "    bind<ApiClient>()\n"
                "        .toProvideAsync(() => createApiClient())\n"
                "        .withName('mainApi')\n"
                "        .singleton();"));
      });

      test('should handle different indentation', () {
        final bindSpec = BindSpec(
          returnType: 'String',
          methodName: 'getString',
          isSingleton: false,
          parameters: [],
          bindingType: BindingType.instance,
          isAsyncInstance: false,
          isAsyncProvide: false,
          hasParams: false,
        );

        final result2 = bindSpec.generateBind(2);
        expect(result2, startsWith('  '));

        final result8 = bindSpec.generateBind(8);
        expect(result8, startsWith('        '));
      });

      test('should handle complex type names', () {
        final bindSpec = BindSpec(
          returnType: 'Map<String, List<User>>',
          methodName: 'getComplexData',
          isSingleton: false,
          parameters: [],
          bindingType: BindingType.provide,
          isAsyncInstance: false,
          isAsyncProvide: false,
          hasParams: false,
        );

        final result = bindSpec.generateBind(4);
        expect(result, contains('bind<Map<String, List<User>>>()'));
        expect(result, contains('toProvide'));
        expect(result, contains('getComplexData'));
      });
    });

    group('BindingType Enum', () {
      test('should have correct enum values', () {
        expect(BindingType.instance, isNotNull);
        expect(BindingType.provide, isNotNull);
        expect(BindingType.values, hasLength(2));
        expect(BindingType.values, contains(BindingType.instance));
        expect(BindingType.values, contains(BindingType.provide));
      });

      test('should have correct string representation', () {
        expect(BindingType.instance.toString(), contains('instance'));
        expect(BindingType.provide.toString(), contains('provide'));
      });
    });
  });
}
