import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';

/// Writes stub sources for the `cherrypick` types the rules match on.
///
/// The plugin deliberately does not depend on `cherrypick`: rules identify
/// types by name plus declaring package URI, so tests only need declarations
/// with the right shape. Must be called from `setUp`, before `super.setUp()`.
void addCherryPickStub(AnalysisRuleTest test) {
  test.newPackage('cherrypick').addFile('lib/cherrypick.dart', r'''
class Scope {
  Future<void> dispose() async {}
  Future<void> closeSubScope(String name) async {}
  Scope openSubScope(String name) => this;
}

class CherryPick {
  static Scope openRootScope() => Scope();
  static Future<void> closeScope({String? scopeName, String separator = '.'}) async {}
  static Future<void> closeRootScope() async {}
}

class MyService {
  void dispose() {}
}
''');
}
