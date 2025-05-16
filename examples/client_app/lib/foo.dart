import 'package:cherrypick_annotations/cherrypick_annotations.dart';

part 'foo.cherrypick_injectable.g.dart';

@Injectable()
class Foo {
  late final String field;
}

// где-то в main:
void iniFoo() {
  $initCherrypickGenerated();
  // ... остальной код
}
