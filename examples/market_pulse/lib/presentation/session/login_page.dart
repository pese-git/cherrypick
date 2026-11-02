import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/workspace_cubit.dart';
import '../../domain/entity/user_session.dart';
import '../theme.dart';

/// Sign-in gate.
///
/// There is no authentication here — the point is the DI transition. Picking a
/// desk opens the `session` subscope, and the whole user-specific half of the
/// graph comes into existence with it.
///
/// [from] is the location the router bounced the visitor away from, so a deep
/// link to `/market/BTCUSD` survives the detour through sign-in.
class LoginPage extends StatelessWidget {
  final String? from;

  const LoginPage({super.key, this.from});

  static const _desks = [('desk-eu', 'Europe desk'), ('desk-us', 'US desk')];

  @override
  Widget build(BuildContext context) {
    // No navigation here: signIn flips Option<UserSession> to some(), the
    // refresh listenable fires, and the router's redirect does the rest.
    void signIn(String userId, String displayName) =>
        context.read<WorkspaceCubit>().signIn(
          UserSession(
            userId: userId,
            displayName: displayName,
            openedAt: DateTime.now(),
          ),
        );

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: MarketColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Market Pulse',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: MarketColors.accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A CherryPick DI showcase. Signing in opens the '
                    '`session` subscope; signing out closes it and disposes '
                    'everything created underneath.',
                    style: TextStyle(color: MarketColors.muted, height: 1.5),
                  ),
                  if (from != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'You will be taken to $from once signed in.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: MarketColors.accent,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  for (final (id, title) in _desks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonal(
                          onPressed: () => signIn(id, title),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text('Sign in as $title'),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
