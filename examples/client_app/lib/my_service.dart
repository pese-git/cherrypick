import 'package:cherrypick_annotations/cherrypick_annotations.dart';

part 'my_service.cherrypick_injectable.g.dart';

@Injectable()
class MyService {}

// где-то в main:
void init() {
  $initCherrypickGenerated();
  // ... остальной код
}
