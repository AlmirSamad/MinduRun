import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_widgets.dart';
import '../room_providers.dart';
import '../../competitions/presentation/competition_widgets.dart';

class RoomDetailsPage extends ConsumerWidget {
  const RoomDetailsPage({super.key, required this.roomId});
  final String roomId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final room = ref.watch(roomDetailsProvider(roomId));
    final members = ref.watch(roomMembersProvider(roomId));
    final owner = room == null
        ? null
        : ref.watch(userRepositoryProvider).getUser(room.ownerUserId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da sala'),
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: room == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Sala não encontrada ou você não participa dela.'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                HeroCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Criador: ${owner?.displayName ?? room.ownerUserId}',
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.key_rounded, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Código de convite',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                    ),
                                  ),
                                  SelectableText(
                                    room.inviteCode,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SectionTitle(
                  'Membros (${room.memberIds.length})',
                  icon: Icons.people_alt_rounded,
                ),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final member in members)
                        ListTile(
                          leading: UserAvatar(name: member.displayName),
                          title: Text(
                            member.displayName,
                            style: theme.textTheme.titleMedium,
                          ),
                          trailing: member.id == room.ownerUserId
                              ? StatusPill(
                                  label: 'Proprietário',
                                  color: theme.colorScheme.tertiary,
                                  icon: Icons.star_rounded,
                                )
                              : null,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                RoomCompetitionsSection(roomId: roomId),
              ],
            ),
    );
  }
}
