import 'dart:async';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

class InjectGenerator extends GeneratorForAnnotation<Injectable> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    print('[TRACE] Processing element: ${element.name}');

    if (element is! FieldElement) {
      throw InvalidGenerationSourceError(
        'Inject can only be used on fields.',
        element: element,
      );
    }

    print('[TRACE] Starting code generation for element: ${element.name}');

    final className = element.enclosingElement.name;
    final fieldName = element.name;
    final fieldType = element.type.getDisplayString(withNullability: false);
    final annotationName = annotation.read('named').stringValue;

    return '''
extension \$${className}Inject on $className {
  void init$fieldName() {
    print("Injected $fieldType named '$annotationName' into $fieldName");
  }
}
''';
  }
}
