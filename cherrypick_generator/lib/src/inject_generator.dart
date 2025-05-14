import 'dart:async';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:cherrypick_annotations/cherrypick_annotations.dart';
import 'package:analyzer/dart/element/element.dart';

class InjectGenerator extends GeneratorForAnnotation<Inject> {
  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! FieldElement) {
      throw InvalidGenerationSourceError(
        'Генератор не может работать с `${element.name}`.',
      );
    }

    final named = annotation.peek('named')?.stringValue;
    final resolveSnippet = named == null
        ? 'CherryPickProvider.of(context).openRootScope().resolve<${element.type}>()'
        : 'CherryPickProvider.of(context).openRootScope().resolve<${element.type}>(named: \'$named\')';

    return '''
void _initState(BuildContext context) {
  ${element.name} = $resolveSnippet;
}
''';
  }
}
