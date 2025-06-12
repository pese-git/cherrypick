//
// Copyright 2021 Sergey Penkovsky (sergey.penkovsky@gmail.com)
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//      http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import 'package:cherrypick_generator/src/bind_spec.dart';
import 'package:test/test.dart';

void main() {
  group('Simple Generator Tests', () {
    group('BindSpec', () {
      test('should create BindSpec with correct properties', () {
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
        expect(bindSpec.bindingType, equals(BindingType.instance));
      });

      test('should generate basic bind code', () {
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
        expect(result, contains('bind<String>()'));
        expect(result, contains('toInstance'));
        expect(result, contains('getString'));
      });

      test('should generate singleton bind code', () {
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
        expect(result, contains('singleton()'));
      });

      test('should generate named bind code', () {
        final bindSpec = BindSpec(
          returnType: 'String',
          methodName: 'getString',
          isSingleton: false,
          named: 'testName',
          parameters: [],
          bindingType: BindingType.instance,
          isAsyncInstance: false,
          isAsyncProvide: false,
          hasParams: false,
        );

        final result = bindSpec.generateBind(4);
        expect(result, contains("withName('testName')"));
      });

      test('should generate provide bind code', () {
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
        expect(result, contains('toProvide'));
        expect(result, contains('() => getString'));
      });

      test('should generate async provide bind code', () {
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
        expect(result, contains('toProvideAsync'));
      });

      test('should generate params bind code', () {
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
        expect(result, contains('toProvideWithParams'));
        expect(result, contains('(args) => getString()'));
      });

      test('should generate complex bind with all options', () {
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
        expect(result, contains('bind<ApiClient>()'));
        expect(result, contains('toProvideAsync'));
        expect(result, contains("withName('mainApi')"));
        expect(result, contains('singleton()'));
      });
    });

    group('BindingType Enum', () {
      test('should have correct values', () {
        expect(BindingType.instance, isNotNull);
        expect(BindingType.provide, isNotNull);
        expect(BindingType.values.length, equals(2));
      });
    });

    group('Generator Classes', () {
      test('should be able to import generators', () {
        // Test that we can import the generator classes
        expect(BindSpec, isNotNull);
        expect(BindingType, isNotNull);
      });
    });
  });
}
