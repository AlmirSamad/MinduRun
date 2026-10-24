import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_widgets.dart';
import '../../session/presentation/rename_dialog.dart';
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
        title: const MinduLogo(height: 34),
        actions: [
          const DemoMenu(),
          // Synced mode keeps one identity per phone: no profile switching.
          if (ref.watch(appModeProvider) == AppMode.demo)
            IconButton(
              tooltip: 'Trocar usuário',
              icon: const Icon(Icons.switch_account_rounded),
              onPressed: () =>
                  ref.read(sessionControllerProvider.notifier).logout(),
            )
          else
            IconButton(
              tooltip: 'Alterar nome',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const RenameDialog(),
              ),
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
                  radius: 28,
                  onDark: true,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bora correr?', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        'Usuário atual: ${user?.displayName ?? ''}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary),
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
                  style: AppTheme.energyButton(),
                  icon: const Icon(Icons.add_rounded),
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
                  icon: const Icon(Icons.key_rounded),
                  label: const FittedBox(child: Text('Entrar com código')),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const RoomFormDialog(join: true),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text('Minhas salas', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          if (rooms.isEmpty)
            const EmptyState(
              icon: Icons.group_rounded,
              message: 'Você ainda não participa de nenhuma sala.\nCrie uma sala ou entre usando um código.',
            ),
          for (final room in rooms)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: ValueKey('room-${room.id}'),
                  onTap: () => context.push(AppRoutes.room(room.id)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const IconBadge(icon: Icons.group_rounded),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                room.name,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${room.memberIds.length} membros • Ver sala',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _MemberStack(roomId: room.id),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Up to three overlapping member avatars with a surface ring.
class _MemberStack extends ConsumerWidget {
  const _MemberStack({required this.roomId});
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(roomMembersProvider(roomId)).take(3).toList();
    if (members.isEmpty) return const SizedBox.shrink();
    const size = 26.0;
    const overlap = 16.0;
    return SizedBox(
      width: size + overlap * (members.length - 1),
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < members.length; i++)
            Positioned(
              left: overlap * i,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                ),
                padding: const EdgeInsets.all(2),
                child: UserAvatar(
                  name: members[i].displayName,
                  radius: size / 2 - 2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
