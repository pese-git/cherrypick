import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../router/app_router.gr.dart';
import '../bloc/post_bloc.dart';

@RoutePage()
class PostsPage extends StatelessWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          context.read<PostBloc>()..add(const PostEvent.fetchAll()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Posts'),
          actions: [
            IconButton(
              icon: const Icon(Icons.bug_report),
              tooltip: 'Open logs',
              onPressed: () {
                AutoRouter.of(context).push(const LogsRoute());
              },
            ),
          ],
        ),
        body: BlocBuilder<PostBloc, PostState>(
          builder: (context, state) {
            return state.when(
              initial: () => const SizedBox.shrink(),
              loading: () => const Center(child: CircularProgressIndicator()),
              loaded: (posts) => ListView.builder(
                itemCount: posts.length,
                itemBuilder: (ctx, i) => ListTile(
                  title: Text(posts[i].title),
                  subtitle: Text(posts[i].body),
                  onTap: () {
                    AutoRouter.of(context)
                        .push(PostDetailsRoute(post: posts[i]));
                  },
                ),
              ),
              failure: (msg) => Center(child: Text('Error: $msg')),
            );
          },
        ),
      ),
    );
  }
}
