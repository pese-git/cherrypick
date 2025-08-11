import 'package:cherrypick/cherrypick.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:postly/app.dart';
import 'package:postly/di/core_module.dart';
import 'package:talker_bloc_logger/talker_bloc_logger_observer.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'di/app_module.dart';
import 'package:talker_cherrypick_logger/talker_cherrypick_logger.dart';

void main() {
  final talker = Talker();
  final talkerLogger = TalkerCherryPickObserver(talker);


  Bloc.observer = TalkerBlocObserver(talker: talker);

  CherryPick.setGlobalObserver(talkerLogger);
  // Включаем cycle-detection только в debug/test
  if (kDebugMode) {
    CherryPick.enableGlobalCycleDetection();
    CherryPick.enableGlobalCrossScopeCycleDetection();
  }

  // Используем safe root scope для гарантии защиты
  CherryPick.openRootScope().installModules([CoreModule(talker: talker), $AppModule()]);

  runApp(MyApp(talker: talker,));
}
