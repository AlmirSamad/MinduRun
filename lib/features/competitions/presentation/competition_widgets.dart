import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_widgets.dart';
import '../../../core/models/models.dart';
import '../../../core/services/competition_countdown.dart';
import '../competition_providers.dart';
import 'create_competition_dialog.dart';

String formatCompetitionDate(DateTime date) {
  final local = date.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
}

/// Effective status right now; no cached stored status and no timer.
CompetitionStatus watchCompetitionStatus(
  WidgetRef ref,
  Competition competition,
) => ref
    .watch(competitionStateServiceProvider)
    .effectiveStatus(competition, ref.watch(clockProvider)());

/// Re-evaluated on every build; no cached stored status and no timer.
class CompetitionStatusBadge extends ConsumerWidget {
  const CompetitionStatusBadge({super.key, required this.competition});
  final Competition competition;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (label, color, icon) = switch (watchCompetitionStatus(
      ref,
      competition,
    )) {
      CompetitionStatus.scheduled => (
        'AGENDADA',
        AppColors.scheduled,
        Icons.event_rounded,
      ),
      CompetitionStatus.active => (
        'ATIVA',
        AppColors.active,
        Icons.local_fire_department_rounded,
      ),
      CompetitionStatus.finished => (
        'FINALIZADA',
        AppColors.finished,
        Icons.sports_score_rounded,
      ),
      CompetitionStatus.cancelled => (
        'CANCELADA',
        AppColors.cancelled,
        Icons.block_rounded,
      ),
    };
    return StatusPill(label: label, color: color, icon: icon);
  }
}

/// Countdown, start/end dates and participant count with icons.
class CompetitionPeriod extends ConsumerWidget {
  const CompetitionPeriod({super.key, required this.competition});
  final Competition competition;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countdown = competitionCountdown(
      competition,
      ref.watch(clockProvider)(),
      state: ref.watch(competitionStateServiceProvider),
    );
    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: AppColors.textSecondary);
    Widget line(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: muted)),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (countdown != null)
          Padding(
            key: const Key('competition-countdown'),
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    countdown,
                    style: muted?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        line(
          Icons.calendar_month_rounded,
          'Início: ${formatCompetitionDate(competition.startsAt)}',
        ),
        line(
          Icons.sports_score_rounded,
          'Término: ${formatCompetitionDate(competition.endsAt)}',
        ),
        line(
          Icons.group_rounded,
          '${competition.participantIds.length} participantes',
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
    final competitions = ref.watch(competitionsForRoomProvider(roomId));
    final canCreate = ref.watch(canCreateCompetitionProvider(roomId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Competições', icon: Icons.emoji_events_rounded),
        if (canCreate) ...[
          FilledButton.icon(
            style: AppTheme.energyButton(),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => CreateCompetitionDialog(roomId: roomId),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Criar competição'),
          ),
          const SizedBox(height: 12),
        ],
        if (competitions.isEmpty)
          const EmptyState(
            icon: Icons.emoji_events_rounded,
            message: 'Nenhuma competição nesta sala.',
          ),
        for (final competition in competitions)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CompetitionCard(competition: competition),
          ),
      ],
    );
  }
}

class _CompetitionCard extends ConsumerWidget {
  const _CompetitionCard({required this.competition});
  final Competition competition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active =
        watchCompetitionStatus(ref, competition) == CompetitionStatus.active;
    void open() => context.push(AppRoutes.competition(competition.id));
    const arrow = Icon(Icons.arrow_forward_rounded);
    const label = Text('Ver competição');
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: active
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              side: BorderSide(
                color: AppColors.accent.withValues(alpha: 0.4),
                width: 2,
              ),
            )
          : null,
      child: InkWell(
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      competition.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CompetitionStatusBadge(competition: competition),
                ],
              ),
              const SizedBox(height: 6),
              CompetitionPeriod(competition: competition),
              const SizedBox(height: 14),
              SizedBox(
                height: 44,
                child: active
                    ? FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                        ),
                        onPressed: open,
                        icon: arrow,
                        iconAlignment: IconAlignment.end,
                        label: label,
                      )
                    : OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                        ),
                        onPressed: open,
                        icon: arrow,
                        iconAlignment: IconAlignment.end,
                        label: label,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
