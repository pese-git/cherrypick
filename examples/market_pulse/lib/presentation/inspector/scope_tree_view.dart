import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/workspace_cubit.dart';
import '../theme.dart';

/// Renders the live scope hierarchy tracked by [WorkspaceCubit].
class ScopeTreeView extends StatelessWidget {
  const ScopeTreeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkspaceCubit, WorkspaceState>(
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _node(context.read<WorkspaceCubit>().buildTree(), 0),
            const SizedBox(height: 16),
            const Text(
              'Every level is a real Scope. Resolution walks up this tree: a '
              'tab finds SelectedFeed one level up and AppConfig at the root.',
              style: TextStyle(
                fontSize: 10,
                height: 1.6,
                color: MarketColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _node(ScopeNode node, int depth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: depth * 16.0, bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                depth == 0
                    ? Icons.account_tree
                    : Icons.subdirectory_arrow_right,
                size: 14,
                color: MarketColors.accent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      node.detail,
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1.5,
                        color: MarketColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        for (final child in node.children) _node(child, depth + 1),
      ],
    );
  }
}
