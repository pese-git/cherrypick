import 'package:flutter/material.dart';
import 'package:cherrypick_flutter/cherrypick_flutter.dart';
import 'use_case.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Разрешение зависимости UseCase из рутового скоупа
    final UseCase useCase =
        CherryPickProvider.of(context).openRootScope().resolve<UseCase>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Example App'),
      ),
      body: Center(
        child: Text(useCase.fetchData()),
      ),
    );
  }
}
