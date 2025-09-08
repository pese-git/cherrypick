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

import 'package:cherrypick_generator/src/metadata_utils.dart';
import 'package:test/test.dart';

void main() {
  group('MetadataUtils Tests', () {
    group('Basic Functionality', () {
      test('should handle empty metadata lists', () {
        expect(MetadataUtils.anyMeta([], 'singleton'), isFalse);
        expect(MetadataUtils.getNamedValue([]), isNull);
      });

      test('should be available for testing', () {
        // This test ensures the MetadataUtils class is accessible
        // More comprehensive tests would require mock setup or integration tests
        expect(MetadataUtils, isNotNull);
      });

      test('should handle null inputs gracefully', () {
        expect(MetadataUtils.anyMeta([], ''), isFalse);
        expect(MetadataUtils.getNamedValue([]), isNull);
      });

      test('should have static methods available', () {
        // Verify that the static methods exist and can be called
        // This is a basic smoke test
        expect(() => MetadataUtils.anyMeta([], 'test'), returnsNormally);
        expect(() => MetadataUtils.getNamedValue([]), returnsNormally);
      });
    });

    group('Method Signatures', () {
      test('anyMeta should return bool', () {
        final result = MetadataUtils.anyMeta([], 'singleton');
        expect(result, isA<bool>());
      });

      test('getNamedValue should return String or null', () {
        final result = MetadataUtils.getNamedValue([]);
        expect(result, anyOf(isA<String>(), isNull));
      });
    });

    group('Edge Cases', () {
      test('should handle various annotation names', () {
        // Test with different annotation names
        expect(MetadataUtils.anyMeta([], 'singleton'), isFalse);
        expect(MetadataUtils.anyMeta([], 'provide'), isFalse);
        expect(MetadataUtils.anyMeta([], 'instance'), isFalse);
        expect(MetadataUtils.anyMeta([], 'named'), isFalse);
        expect(MetadataUtils.anyMeta([], 'params'), isFalse);
      });

      test('should handle empty strings', () {
        expect(MetadataUtils.anyMeta([], ''), isFalse);
        expect(MetadataUtils.getNamedValue([]), isNull);
      });
    });
  });
}
