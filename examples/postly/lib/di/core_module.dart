import 'package:cherrypick/cherrypick.dart';
import 'package:talker_flutter/talker_flutter.dart';

class CoreModule extends Module {
  final Talker _talker;

  CoreModule({required Talker talker}) : _talker = talker;
  
  @override
  void builder(Scope currentScope) {
    bind<Talker>().toProvide(() => _talker).singleton();
  }
}