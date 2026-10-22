import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../session/session_providers.dart';
import '../room_providers.dart';
import 'room_form_dialog.dart';
import '../../demo/presentation/demo_menu.dart';

class RoomsPage extends ConsumerWidget {
  const RoomsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final rooms = ref.watch(currentUserRoomsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('MinduRun'),
        actions: [
          const DemoMenu(),
          IconButton(
            tooltip: 'Trocar usuário',
            icon: const Icon(Icons.switch_account),
            onPressed: () =>
                ref.read(sessionControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Usuário atual: ${user?.displayName ?? ''}'),
          const SizedBox(height: 16),
          Text(
            'Minhas salas',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Criar sala'),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const RoomFormDialog(join: false),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.key),
            label: const Text('Entrar com código'),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const RoomFormDialog(join: true),
            ),
          ),
          const SizedBox(height: 16),
          if (rooms.isEmpty)
            const Text(
              'Você ainda não participa de nenhuma sala.\nCrie uma sala ou entre usando um código.',
            ),
          for (final room in rooms)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  key: ValueKey('room-${room.id}'),
                  title: Text(room.name),
                  subtitle: Text('${room.memberIds.length} membros • Ver sala'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.room(room.id)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
