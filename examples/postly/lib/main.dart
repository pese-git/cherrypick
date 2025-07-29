import 'package:cherrypick/cherrypick.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:postly/app.dart';
import 'di/app_module.dart';

void main() {
  // Включаем cycle-detection только в debug/test
  if (kDebugMode) {
    CherryPick.enableGlobalCycleDetection();
    CherryPick.enableGlobalCrossScopeCycleDetection();
  }

  // Используем safe root scope для гарантии защиты
  CherryPick.openRootScope().installModules([$AppModule()]);
  runApp(MyApp());
}
