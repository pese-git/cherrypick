// ... остальные импорты ...
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:cherrypick_annotations/cherrypick_annotations.dart' as ann;

class ModuleGenerator extends GeneratorForAnnotation<ann.module> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@module() может быть применён только к классам.',
        element: element,
      );
    }
    final classElement = element;
    final className = classElement.displayName;
    final generatedClassName = r'$' + className;
    final buffer = StringBuffer();

    buffer.writeln('final class $generatedClassName extends $className {');
    buffer.writeln('  @override');
    buffer.writeln('  void builder(Scope currentScope) {');
    for (final method in classElement.methods.where((m) => !m.isAbstract)) {
      final hasSingleton = method.metadata.any(
        (m) =>
            m
                .computeConstantValue()
                ?.type
                ?.getDisplayString(withNullability: false)
                .toLowerCase()
                .contains('singleton') ??
            false,
      );
      ElementAnnotation? namedMeta;
      try {
        namedMeta = method.metadata.firstWhere(
          (m) =>
              m
                  .computeConstantValue()
                  ?.type
                  ?.getDisplayString(withNullability: false)
                  .toLowerCase()
                  .contains('named') ??
              false,
        );
      } catch (_) {
        namedMeta = null;
      }
      String? nameArg;
      if (namedMeta != null) {
        final cv = namedMeta.computeConstantValue();
        if (cv != null) {
          nameArg = cv.getField('value')?.toStringValue();
        }
      }
      final returnType =
          method.returnType.getDisplayString(withNullability: false);
      final methodName = method.displayName;
      final args = method.parameters
          .map((p) =>
              "currentScope.resolve<${p.type.getDisplayString(withNullability: false)}>()")
          .join(', ');
      buffer.write('    bind<$returnType>()'
          '.toProvide(() => $methodName($args))');
      if (nameArg != null) {
        buffer.write(".withName('$nameArg')");
      }
      if (hasSingleton) {
        buffer.write('.singleton()');
      }
      buffer.write(';\n');
    }
    buffer.writeln('  }');
    buffer.writeln('}');
    return buffer.toString();
  }
}

Builder moduleBuilder(BuilderOptions options) =>
    PartBuilder([ModuleGenerator()], '.cherrypick.g.dart');
