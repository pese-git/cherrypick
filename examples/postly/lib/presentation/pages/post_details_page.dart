import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../domain/entity/post.dart';

@RoutePage()
class PostDetailsPage extends StatelessWidget {
  final Post post;

  const PostDetailsPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Post #${post.id}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(post.body),
      ),
    );
  }
}
