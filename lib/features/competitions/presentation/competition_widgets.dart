import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_widgets.dart';
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
    final (label, color, icon) = switch (status) {
      CompetitionStatus.scheduled => (
        'AGENDADA',
        const Color(0xFF3D5AFE),
        Icons.schedule_rounded,
      ),
      CompetitionStatus.active => (
        'ATIVA',
        const Color(0xFF0B7A55),
        Icons.bolt_rounded,
      ),
      CompetitionStatus.finished => (
        'FINALIZADA',
        const Color(0xFF616161),
        Icons.flag_rounded,
      ),
      CompetitionStatus.cancelled => (
        'CANCELADA',
        const Color(0xFFC62828),
        Icons.block_rounded,
      ),
    };
    return StatusPill(label: label, color: color, icon: icon);
  }
}

/// Start/end dates with icons.
class CompetitionPeriod extends StatelessWidget {
  const CompetitionPeriod({super.key, required this.competition});
  final Competition competition;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    Widget line(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: muted)),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        line(
          Icons.play_circle_outline_rounded,
          'Início: ${formatCompetitionDate(competition.startsAt)}',
        ),
        line(
          Icons.outlined_flag_rounded,
          'Término: ${formatCompetitionDate(competition.endsAt)}',
        ),
      ],
    );
  }
}

class RoomCompetitionsSection extends ConsumerWidget {
  const RoomCompetitionsSection({super.key, required this.roomId});
  final String roomId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final competitions = ref.watch(competitionsForRoomProvider(roomId));
    final canCreate = ref.watch(canCreateCompetitionProvider(roomId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Competições', icon: Icons.emoji_events_rounded),
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
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () =>
                    context.push(AppRoutes.competition(competition.id)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              competition.name,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(width: 8),
                          CompetitionStatusBadge(competition: competition),
                          const SizedBox(width: 8),
                        ],
                      ),
                      const SizedBox(height: 4),
                      CompetitionPeriod(competition: competition),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => context.push(
                            AppRoutes.competition(competition.id),
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          iconAlignment: IconAlignment.end,
                          label: const Text('Ver competição'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
