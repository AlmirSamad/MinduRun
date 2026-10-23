import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_widgets.dart';
import '../session_providers.dart';
import '../../demo/presentation/demo_menu.dart';

/// Demo profile selector (simulated local session, not real login).
class UserSelectionPage extends ConsumerWidget {
  const UserSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final users = ref.watch(availableUsersProvider);

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 8, 36),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerRight,
                      child: IconTheme(
                        data: IconThemeData(color: Colors.white),
                        child: DemoMenu(),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_run_rounded,
                        size: 52,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'MinduRun',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Corra com seus amigos. Compita. Valide.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Quem está usando o app?',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Escolha um perfil de demonstração.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                if (users.isEmpty)
                  const Text(
                    'Nenhum usuário disponível.',
                    textAlign: TextAlign.center,
                  ),
                for (final user in users)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        key: Key('select-user-${user.id}'),
                        minTileHeight: 68,
                        leading: UserAvatar(name: user.displayName),
                        title: Text(
                          user.displayName,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        onTap: () => ref
                            .read(sessionControllerProvider.notifier)
                            .selectUser(user),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
