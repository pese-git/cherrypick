import 'package:cherrypick/cherrypick.dart';
import 'package:cherrypick_annotations/cherrypick_annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';


import 'domain/repository/post_repository.dart';
import 'presentation/bloc/post_bloc.dart';
import 'router/app_router.dart';

part 'app.inject.cherrypick.g.dart';

class TalkerProvider extends InheritedWidget {
  final Talker talker;
  const TalkerProvider({required this.talker, required super.child, super.key});
  static Talker of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<TalkerProvider>()!.talker;
  @override
  bool updateShouldNotify(TalkerProvider oldWidget) => oldWidget.talker != talker;
}

@injectable()
class MyApp extends StatelessWidget with _$MyApp {
  final _appRouter = AppRouter();
  final Talker talker;

  @named('repo')
  @inject()
  late final PostRepository repository;

  MyApp({super.key, required this.talker}) {
    _inject(this);
  }

  @override
  Widget build(BuildContext context) {
    return TalkerProvider(
      talker: talker,
      child: BlocProvider(
        create: (_) => PostBloc(repository),
        child: MaterialApp.router(
          routeInformationParser: _appRouter.defaultRouteParser(),
          routerDelegate: _appRouter.delegate(),
          theme: ThemeData.light(),
        ),
      ),
    );
  }
}
