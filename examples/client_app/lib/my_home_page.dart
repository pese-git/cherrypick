import 'package:flutter/material.dart';
import 'use_case.dart';

class MyHomePage extends StatelessWidget {
  late final UseCase useCase;

  // ignore: prefer_const_constructors_in_immutables
  MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    //_inject(context); // Make sure this function is called in context
    return Scaffold(
      appBar: AppBar(title: const Text('Example App')),
      body: Center(child: Text(useCase.fetchData())),
    );
  }
}
