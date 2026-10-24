import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_widgets.dart';
import '../../session/session_providers.dart';
import '../room_providers.dart';
import 'room_form_dialog.dart';
import '../../demo/presentation/demo_menu.dart';

class RoomsPage extends ConsumerWidget {
  const RoomsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final rooms = ref.watch(currentUserRoomsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.directions_run_rounded,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            const Text('MinduRun'),
          ],
        ),
        actions: [
          const DemoMenu(),
          // Synced mode keeps one identity per phone: no profile switching.
          if (ref.watch(appModeProvider) == AppMode.demo)
            IconButton(
              tooltip: 'Trocar usuário',
              icon: const Icon(Icons.switch_account),
              onPressed: () =>
                  ref.read(sessionControllerProvider.notifier).logout(),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          HeroCard(
            child: Row(
              children: [
                UserAvatar(
                  name: user?.displayName ?? '',
                  radius: 26,
                  onDark: true,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bora correr?',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Usuário atual: ${user?.displayName ?? ''}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Criar sala'),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const RoomFormDialog(join: false),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.key),
                  label: const FittedBox(child: Text('Entrar com código')),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const RoomFormDialog(join: true),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Minhas salas', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          if (rooms.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.groups_outlined,
                      size: 40,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Você ainda não participa de nenhuma sala.\nCrie uma sala ou entre usando um código.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          for (final room in rooms)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  key: ValueKey('room-${room.id}'),
                  minTileHeight: 72,
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.groups_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(room.name, style: theme.textTheme.titleMedium),
                  subtitle: Text('${room.memberIds.length} membros • Ver sala'),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  onTap: () => context.push(AppRoutes.room(room.id)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
