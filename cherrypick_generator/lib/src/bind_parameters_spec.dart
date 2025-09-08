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

/// ----------------------------------------------------------------------------
/// BindParameterSpec
///
/// Describes a single parameter for a DI provider/factory/binding method,
/// specifying how that parameter is to be resolved in generated code.
///
/// Stores the parameter's type name, optional `@named` identifier (for named DI resolution),
/// and a flag for runtime (@params) arguments. Used in CherryPick generator
/// for creating argument lists when invoking factories or provider methods.
///
/// ## Example usage
/// ```dart
/// // Binding method: @provide() Logger provideLogger(@named('debug') Config config, @params Map<String, dynamic> args)
/// final namedParam = BindParameterSpec('Config', 'debug');
/// final runtimeParam = BindParameterSpec('Map<String, dynamic>', null, isParams: true);
/// print(namedParam.generateArg()); // prints: currentScope.resolve<Config>(named: 'debug')
/// print(runtimeParam.generateArg()); // prints: args
/// ```
///
/// ## Code generation logic
/// - Injected:  currentScope.resolve<Service>()
/// - Named:     currentScope.resolve<Service>(named: 'name')
/// - @params:   args
/// ----------------------------------------------------------------------------
class BindParameterSpec {
  /// The type name of the parameter (e.g., 'UserRepository')
  final String typeName;

  /// If non-null, this is the named-key for DI resolution (from @named).
  final String? named;

  /// True if this parameter is a runtime param (annotated with @params and
  /// filled by a runtime argument map).
  final bool isParams;

  BindParameterSpec(this.typeName, this.named, {this.isParams = false});

  /// Generates Dart code to resolve this parameter in the DI container.
  ///
  /// - For normal dependencies: resolves by type
  /// - For named dependencies: resolves by type and name
  /// - For @params: uses the supplied params variable (default 'args')
  ///
  /// ## Example
  /// ```dart
  /// final a = BindParameterSpec('Api', null); // normal
  /// print(a.generateArg()); // currentScope.resolve<Api>()
  ///
  /// final b = BindParameterSpec('Api', 'prod'); // named
  /// print(b.generateArg()); // currentScope.resolve<Api>(named: 'prod')
  ///
  /// final c = BindParameterSpec('Map<String,dynamic>', null, isParams: true); // params
  /// print(c.generateArg()); // args
  /// ```
  String generateArg([String paramsVar = 'args']) {
    if (isParams) {
      return paramsVar;
    }
    if (named != null) {
      return "currentScope.resolve<$typeName>(named: '$named')";
    }
    return "currentScope.resolve<$typeName>()";
  }
}
