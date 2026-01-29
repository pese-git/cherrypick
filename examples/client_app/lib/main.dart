import 'package:cherrypick/cherrypick.dart';
import 'package:client_app/my_home_page.dart';
import 'package:flutter/material.dart';
import 'package:cherrypick_flutter/cherrypick_flutter.dart';

void main() {
  // Здесь происходит инициализация рутового скоупа и привязка зависимостей
  CherryPick.openRootScope().installModules([
    // Создаем модуль, который будет предоставлять UseCase
  ]);

  runApp(const CherryPickProvider(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CherryPickProvider(child: MaterialApp(home: MyHomePage()));
  }
}
