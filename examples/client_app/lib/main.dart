import 'package:cherrypick/cherrypick.dart';
import 'package:flutter/material.dart';
import 'package:cherrypick_flutter/cherrypick_flutter.dart';
import 'my_home_page.dart';
import 'use_case.dart';

void main() {
  // Здесь происходит инициализация рутового скоупа и привязка зависимостей
  CherryPick.openRootScope().installModules([
    // Создаем модуль, который будет предоставлять UseCase
    ModuleWithUseCase(),
  ]);

  runApp(
    const CherryPickProvider(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Example App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(),
    );
  }
}

// Модуль для настройки зависимостей
class ModuleWithUseCase extends Module {
  @override
  void builder(Scope currentScope) {
    // Привязка UseCase как singleton
    bind<UseCase>().toInstance(UseCase());
  }
}
