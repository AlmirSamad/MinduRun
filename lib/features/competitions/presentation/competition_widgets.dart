import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/router/app_router.dart';
import '../../../core/models/models.dart';
import '../competition_providers.dart';
import 'create_competition_dialog.dart';

String formatCompetitionDate(DateTime date) {
  final local = date.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
}

/// Re-evaluated on every build; no cached stored status and no timer.
class CompetitionStatusBadge extends ConsumerWidget {
  const CompetitionStatusBadge({super.key, required this.competition});
  final Competition competition;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref
        .watch(competitionStateServiceProvider)
        .effectiveStatus(competition, ref.watch(clockProvider)());
    final label = switch (status) {
      CompetitionStatus.scheduled => 'AGENDADA',
      CompetitionStatus.active => 'ATIVA',
      CompetitionStatus.finished => 'FINALIZADA',
      CompetitionStatus.cancelled => 'CANCELADA',
    };
    return Chip(label: Text(label), visualDensity: VisualDensity.compact);
  }
}

class RoomCompetitionsSection extends ConsumerWidget {
  const RoomCompetitionsSection({super.key, required this.roomId});
  final String roomId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitions = ref.watch(competitionsForRoomProvider(roomId));
    final canCreate = ref.watch(canCreateCompetitionProvider(roomId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Competições', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (canCreate) ...[
          FilledButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => CreateCompetitionDialog(roomId: roomId),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Criar competição'),
          ),
          const SizedBox(height: 12),
        ],
        if (competitions.isEmpty) const Text('Nenhuma competição nesta sala.'),
        for (final competition in competitions)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      competition.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    CompetitionStatusBadge(competition: competition),
                    Text(
                      'Início: ${formatCompetitionDate(competition.startsAt)}',
                    ),
                    Text(
                      'Término: ${formatCompetitionDate(competition.endsAt)}',
                    ),
                    TextButton(
                      onPressed: () =>
                          context.push(AppRoutes.competition(competition.id)),
                      child: const Text('Ver competição'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
