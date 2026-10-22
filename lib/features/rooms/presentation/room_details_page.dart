import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/router/app_router.dart';
import '../room_providers.dart';
import '../../competitions/presentation/competition_widgets.dart';

class RoomDetailsPage extends ConsumerWidget {
  const RoomDetailsPage({super.key, required this.roomId});
  final String roomId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  room.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                const Text('Código de convite'),
                SelectableText(
                  room.inviteCode,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Text('Criador: ${owner?.displayName ?? room.ownerUserId}'),
                const SizedBox(height: 24),
                Text(
                  'Membros (${room.memberIds.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final member in members)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(member.displayName),
                      subtitle: member.id == room.ownerUserId
                          ? const Text('Proprietário')
                          : null,
                    ),
                  ),
                const SizedBox(height: 24),
                RoomCompetitionsSection(roomId: roomId),
              ],
            ),
    );
  }
}
