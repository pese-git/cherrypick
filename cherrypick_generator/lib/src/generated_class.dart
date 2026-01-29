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
import 'package:analyzer/dart/element/element2.dart';
import 'bind_spec.dart';

/// ---------------------------------------------------------------------------
/// GeneratedClass
///
/// Represents a processed DI module class with all its binding methods analyzed.
/// Stores:
///   - The original class name,
///   - The generated implementation class name (with $ prefix),
///   - The list of all BindSpec for the module methods,
///   - The source file name for reference or directive generation.
///
/// Provides static and instance methods to construct from a ClassElement
/// and generate Dart source code for the resulting DI registration class.
///
/// ## Example usage
/// ```dart
/// final gen = GeneratedClass.fromClassElement(myModuleClassElement);
/// print(gen.generate());
/// /*
/// Produces:
/// final class $MyModule extends MyModule {
///   @override
///   void builder(Scope currentScope) {
///     bind<Service>().toProvide(() => provideService(currentScope.resolve<Dep>()));
///     ...
///   }
/// }
/// */
/// ```
/// ---------------------------------------------------------------------------
class GeneratedClass {
  /// Name of the original Dart module class.
  final String className;

  /// Name of the generated class, e.g. `$MyModule`
  final String generatedClassName;

  /// Binding specs for all provider/factory methods in the class.
  final List<BindSpec> binds;

  /// Source filename of the module class (for code references).
  final String sourceFile;

  GeneratedClass(
    this.className,
    this.generatedClassName,
    this.binds,
    this.sourceFile,
  );

  /// -------------------------------------------------------------------------
  /// fromClassElement
  ///
  /// Creates a [GeneratedClass] by analyzing a Dart [ClassElement].
  /// Collects all public non-abstract methods, creates a [BindSpec] for each,
  /// and infers the generated class name using a `$` prefix.
  ///
  /// ## Example usage
  /// ```dart
  /// final gen = GeneratedClass.fromClassElement(classElement);
  /// print(gen.generatedClassName); // e.g. $AppModule
  /// ```
  static GeneratedClass fromClassElement(ClassElement2 element) {
    final className = element.firstFragment.name2 ?? '';
    final generatedClassName = r'$' + className;
    final sourceFile = element.firstFragment.libraryFragment.source.shortName;
    final binds = element.methods2
        .where((m) => !m.isAbstract)
        .map(BindSpec.fromMethod)
        .toList();

    return GeneratedClass(className, generatedClassName, binds, sourceFile);
  }

  /// -------------------------------------------------------------------------
  /// generate
  ///
  /// Generates the Dart source code for the DI registration class.
  /// The generated class extends the original module, and the `builder` method
  /// registers all bindings (dependencies) into the DI scope.
  ///
  /// ## Example output
  /// ```dart
  /// final class $UserModule extends UserModule {
  ///   @override
  ///   void builder(Scope currentScope) {
  ///     bind<Service>().toProvide(() => provideService(currentScope.resolve<Dep>()));
  ///   }
  /// }
  /// ```
  String generate() {
    final buffer = StringBuffer()
      ..writeln('final class $generatedClassName extends $className {')
      ..writeln('  @override')
      ..writeln('  void builder(Scope currentScope) {');

    // For each binding, generate bind<Type>() code string.
    for (final bind in binds) {
      buffer.writeln(bind.generateBind(4));
    }

    buffer
      ..writeln('  }')
      ..writeln('}');

    return buffer.toString();
  }
}
