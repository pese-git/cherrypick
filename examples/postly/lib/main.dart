import 'package:cherrypick/cherrypick.dart';
import 'package:flutter/material.dart';
import 'package:postly/app.dart';
import 'di/app_module.dart';

void main() {
  CherryPick.openRootScope().installModules([$AppModule()]);
  runApp(MyApp());
}
