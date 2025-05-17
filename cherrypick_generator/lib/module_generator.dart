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

      // ЗДЕСЬ ЛОГИКА ДЛЯ ПАРАМЕТРОВ МЕТОДА
      final args = method.parameters.map((p) {
        // Ищем @named у параметра
        ElementAnnotation? paramNamed;
        try {
          paramNamed = p.metadata.firstWhere(
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
          paramNamed = null;
        }
        String namedArg = '';
        if (paramNamed != null) {
          final cv = paramNamed.computeConstantValue();
          if (cv != null) {
            final namedValue = cv.getField('value')?.toStringValue();
            if (namedValue != null) {
              namedArg = "(named: '$namedValue')";
            }
          }
        }
        return "currentScope.resolve<${p.type.getDisplayString(withNullability: false)}>$namedArg";
      }).join(', ');

      final returnType =
          method.returnType.getDisplayString(withNullability: false);
      final methodName = method.displayName;
      // С переносом строки, если есть параметры
      final hasLongArgs = args.length > 60 || args.contains('\n');
      if (hasLongArgs) {
        buffer.write('    bind<$returnType>()\n'
            '      .toProvide(\n        () => $methodName($args))');
      } else {
        buffer.write('    bind<$returnType>()'
            '.toProvide(() => $methodName($args))');
      }
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
