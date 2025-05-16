import 'package:cherrypick_annotations/cherrypick_annotations.dart';
import 'package:flutter/material.dart';
import 'use_case.dart';

part 'my_home_page.cherrypick_injectable.g.dart';

@Injectable()
class MyHomePage extends StatelessWidget {
  late final UseCase useCase;

  // ignore: prefer_const_constructors_in_immutables
  MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    //_inject(context); // Make sure this function is called in context
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
