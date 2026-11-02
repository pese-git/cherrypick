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

import 'package:analyzer/dart/element/element.dart';

/// ---------------------------------------------------------------------------
/// MetadataUtils
///
/// Static utilities for querying and extracting information from
/// Dart annotations ([ElementAnnotation]) in the context of code generation,
/// such as checking for the presence of specific DI-related annotations.
/// Designed to be used internally by code generation and validation routines.
///
/// # Example usage
/// ```dart
/// if (MetadataUtils.anyMeta(method.metadata.annotations, 'singleton')) {
///   // The method is annotated with @singleton
/// }
/// final name = MetadataUtils.getNamedValue(field.metadata.annotations);
/// if (name != null) print('@named value: $name');
/// ```
/// ---------------------------------------------------------------------------
class MetadataUtils {
  /// Checks whether any annotation in [meta] matches the [typeName]
  /// (type name is compared in a case-insensitive manner and can be partial).
  ///
  /// Returns true if an annotation (such as @singleton, @provide, @named) is found.
  ///
  /// Example:
  /// ```dart
  /// bool isSingleton = MetadataUtils.anyMeta(myMethod.metadata.annotations, 'singleton');
  /// ```
  static bool anyMeta(List<ElementAnnotation> meta, String typeName) {
    return meta.any(
      (m) =>
          m
              .computeConstantValue()
              ?.type
              ?.getDisplayString()
              .toLowerCase()
              .contains(typeName.toLowerCase()) ??
          false,
    );
  }

  /// Extracts the string value from a `@named('value')` annotation if present in [meta].
  ///
  /// Returns the named value or `null` if not annotated.
  ///
  /// Example:
  /// ```dart
  /// // For: @named('dev') ApiClient provideApi() ...
  /// final named = MetadataUtils.getNamedValue(method.metadata); // 'dev'
  /// ```
  static String? getNamedValue(List<ElementAnnotation> meta) {
    for (final m in meta) {
      final cv = m.computeConstantValue();

      final typeStr = cv?.type?.getDisplayString().toLowerCase();

      if (typeStr?.contains('named') ?? false) {
        return cv?.getField('value')?.toStringValue();
      }
    }

    return null;
  }
}
