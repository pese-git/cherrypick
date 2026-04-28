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

import 'package:code_builder/code_builder.dart';

import 'type_parser.dart';

/// Small helpers for building code_builder AST nodes used by generators.
class CodeBuilderEmitters {
  /// Builds a CherryPick scope opener expression.
  ///
  /// - If [scopeName] is empty or null, uses openRootScope().
  /// - Otherwise uses openScope(scopeName: ...).
  static Expression openScope({String? scopeName}) {
    if (scopeName == null || scopeName.isEmpty) {
      return refer('CherryPick').property('openRootScope').call([]);
    }
    return refer(
      'CherryPick',
    ).property('openScope').call([], {'scopeName': literalString(scopeName)});
  }

  /// Builds a TypeReference appropriate for resolving a dependency.
  ///
  /// For Future<T>, it returns the inner type reference (T).
  /// Nullability and generic arguments are preserved.
  static TypeReference resolveTypeRef(ParsedType parsedType) {
    final target = parsedType.isFuture && parsedType.innerType != null
        ? parsedType.innerType!
        : parsedType;
    return _typeRefFromParsedType(target, stripNullability: true);
  }

  /// Builds a DI resolve call on [scopeExpr] using [parsedType] and [named].
  ///
  /// The method name is derived from [ParsedType.resolveMethodName].
  static Expression resolveCall({
    required Expression scopeExpr,
    required ParsedType parsedType,
    String? named,
  }) {
    final typeRef = resolveTypeRef(parsedType);
    final method = parsedType.resolveMethodName;
    final args = <Expression>[];
    final namedArgs = <String, Expression>{};
    if (named != null && named.isNotEmpty) {
      namedArgs['named'] = literalString(named);
    }
    return scopeExpr.property(method).call(args, namedArgs, [typeRef]);
  }

  static TypeReference _typeRefFromParsedType(
    ParsedType parsedType, {
    required bool stripNullability,
  }) {
    return TypeReference((b) {
      b
        ..symbol = parsedType.coreType
        ..isNullable = stripNullability ? false : parsedType.isNullable;
      if (parsedType.typeArguments.isNotEmpty) {
        b.types.addAll(
          parsedType.typeArguments.map(
            (arg) =>
                _typeRefFromParsedType(arg, stripNullability: stripNullability),
          ),
        );
      }
    });
  }
}
