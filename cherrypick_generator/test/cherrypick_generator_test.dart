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

import 'package:test/test.dart';

// Import working test suites
import 'simple_test.dart' as simple_tests;
import 'bind_spec_test.dart' as bind_spec_tests;
import 'metadata_utils_test.dart' as metadata_utils_tests;
// Import integration test suites (now working!)
import 'module_generator_test.dart' as module_generator_tests;
import 'inject_generator_test.dart' as inject_generator_tests;

void main() {
  group('CherryPick Generator Tests', () {
    group('Simple Tests', simple_tests.main);
    group('BindSpec Tests', bind_spec_tests.main);
    group('MetadataUtils Tests', metadata_utils_tests.main);
    group('ModuleGenerator Tests', module_generator_tests.main);
    group('InjectGenerator Tests', inject_generator_tests.main);
  });
}
