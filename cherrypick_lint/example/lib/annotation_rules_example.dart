// Fixtures for the annotation-rules group.
// Run `dart run custom_lint` from this package to check them.
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@module()
// expect_lint: module_must_be_abstract
class BadModule {
  @provide()
  String provideName() => 'name';
}

@module()
abstract class GoodModule {
  @provide()
  String provideName() => 'name';

  // expect_lint: module_method_missing_binding
  String missingBinding() => 'oops';

  // ignore: unused_element
  String _privateHelper() => 'ok';
}

class BadInjectable {
  @inject()
  // expect_lint: inject_field_must_be_late_final
  String service = '';
}

class GoodInjectable {
  @inject()
  late final String service;
}

@module()
abstract class NamedModule {
  // expect_lint: named_value_must_not_be_empty
  @named('')
  @provide()
  String badName() => 'x';

  @named('main')
  @provide()
  String goodName() => 'x';
}

@module()
abstract class ParamsModule {
  @params()
  // expect_lint: params_requires_provide, module_method_missing_binding
  String badParams() => 'x';

  @provide()
  @params()
  String goodParams() => 'x';
}
