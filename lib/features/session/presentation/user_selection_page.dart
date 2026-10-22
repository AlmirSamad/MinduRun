import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      appBar: AppBar(actions: const [DemoMenu()]),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          children: [
            Icon(
              Icons.directions_run,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'MinduRun',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Quem está usando o app?',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Escolha um perfil de demonstração.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (users.isEmpty)
              const Text(
                'Nenhum usuário disponível.',
                textAlign: TextAlign.center,
              ),
            for (final user in users)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    key: Key('select-user-${user.id}'),
                    minTileHeight: 64,
                    leading: CircleAvatar(
                      child: Text(user.displayName.characters.first),
                    ),
                    title: Text(
                      user.displayName,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => ref
                        .read(sessionControllerProvider.notifier)
                        .selectUser(user),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
