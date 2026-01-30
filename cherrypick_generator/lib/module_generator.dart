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
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:cherrypick_annotations/cherrypick_annotations.dart' as ann;

import 'src/generated_class.dart';

/// ---------------------------------------------------------------------------
/// CherryPick Module Generator — Codegen for DI modules
///
/// This generator scans Dart classes annotated with `@module()` and generates
/// boilerplate for dependency injection registration automatically. Each public
/// method in such classes can be annotated to describe how an object should be
/// bound to the DI container (singleton, factory, named, with parameters, etc).
///
/// The generated code collects all such bind methods and produces a Dart
/// companion *module registration class* with a `.bindAll()` method, which you
/// can use from your DI root to automatically register those dependencies.
///
/// ## Example
/// ```dart
/// import 'package:cherrypick_annotations/cherrypick_annotations.dart';
///
/// @module()
/// abstract class AppModule {
///   @singleton()
///   Logger logger() => Logger();
///
///   @provide()
///   ApiService api(Logger logger) => ApiService(logger);
///
///   @named('dev')
///   FakeService fake() => FakeService();
/// }
/// ```
///
/// After codegen, you will get (simplified):
/// ```dart
/// class _\$AppModuleCherrypickModule extend AppModule {
///   static void bindAll(CherryPickScope scope, AppModule module) {
///     scope.addSingleton<Logger>(() => module.logger());
///     scope.addFactory<ApiService>(() => module.api(scope.resolve<Logger>()));
///     scope.addFactory<FakeService>(() => module.fake(), named: 'dev');
///   }
/// }
/// ```
///
/// Use it e.g. in your bootstrap:
/// ```dart
/// final scope = CherryPick.openRootScope()..intallModules([_\$AppModuleCherrypickModule()]);
/// ```
///
/// Features supported:
/// - Singleton, factory, named, parametric, and async providers
/// - Eliminates all boilerplate for DI registration
/// - Works with abstract classes and real classes
/// - Error if @module() is applied to a non-class
///
/// See also: [@singleton], [@provide], [@named], [@module]
/// ---------------------------------------------------------------------------

class ModuleGenerator extends GeneratorForAnnotation<ann.module> {
  /// Generates Dart source for a class marked with the `@module()` annotation.
  ///
  /// Throws [InvalidGenerationSourceError] if used on anything except a class.
  ///
  /// See file-level docs for usage and generated output example.
  @override
  dynamic generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@module() can only be applied to classes.',
        element: element,
      );
    }

    final classElement = element;
    final generatedClass = GeneratedClass.fromClassElement(classElement);
    return generatedClass.generate();
  }
}

/// ---------------------------------------------------------------------------
/// Codegen builder entry point: register this builder in build.yaml or your package.
///
/// Used by build_runner. Generates .module.cherrypick.g.dart files for each
/// source file with an annotated @module() class.
/// ---------------------------------------------------------------------------
Builder moduleBuilder(BuilderOptions options) =>
    PartBuilder([ModuleGenerator()], '.module.cherrypick.g.dart');
