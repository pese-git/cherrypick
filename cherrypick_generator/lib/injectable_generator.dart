import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

class InjectableGenerator extends GeneratorForAnnotation<Injectable> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! ClassElement) return null;

    final className = element.name;

    // Используйте уникальное имя функции (например, привязанное к файлу/классу)
    return '''
void \$initCherrypickGenerated() {
  print("Generate code success $className");
}
''';
  }
}

Builder injectableBuilder(BuilderOptions options) =>
    PartBuilder([InjectableGenerator()], '.cherrypick_injectable.g.dart');

/*
Builder injectableBuilder(BuilderOptions options) => SharedPartBuilder(
      [InjectableGenerator()],
      'injectable',
      allowSyntaxErrors: true,
      writeDescriptions: true,
    );
*/
