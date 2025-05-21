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

import 'package:analyzer/dart/element/element.dart';

///
/// Утилиты для разбора аннотаций методов и параметров.
/// Позволяют найти @named() и @singleton() у метода/параметра.
///
class MetadataUtils {
  /// Проверяет: есть ли среди аннотаций метка, имя которой содержит [typeName]
  /// (регистр не учитывается)
  static bool anyMeta(List<ElementAnnotation> meta, String typeName) {
    return meta.any((m) =>
        m
            .computeConstantValue()
            ?.type
            ?.getDisplayString()
            .toLowerCase()
            .contains(typeName.toLowerCase()) ??
        false);
  }

  /// Находит значение из аннотации @named('значение').
  /// Возвращает строку значения, если аннотация присутствует; иначе null.
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
