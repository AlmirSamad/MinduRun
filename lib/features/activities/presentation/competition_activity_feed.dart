import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_widgets.dart';
import '../../../core/services/activity_input.dart';
import '../../../core/models/models.dart';
import '../../competitions/presentation/competition_widgets.dart';
import '../activity_providers.dart';
import 'evidence_image.dart';
import '../../moderation/presentation/moderation_dialogs.dart';
import '../../social/presentation/activity_social_bar.dart';

class CompetitionActivityFeed extends ConsumerWidget {
  const CompetitionActivityFeed({super.key, required this.competitionId});
  final String competitionId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(
      activitiesForCompetitionProvider(competitionId),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Atividades', icon: Icons.directions_run_rounded),
        if (activities.isEmpty)
          const EmptyState(
            icon: Icons.directions_run_rounded,
            message: 'Nenhuma atividade registrada ainda.',
          ),
        for (final activity in activities)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ActivityCard(activity: activity),
          ),
      ],
    );
  }
}

class _ActivityCard extends ConsumerWidget {
  const _ActivityCard({required this.activity});
  final Activity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name =
        ref
            .watch(userRepositoryProvider)
            .getUser(activity.userId)
            ?.displayName ??
        activity.userId;
    final rejected =
        activity.moderationStatus == ActivityModerationStatus.rejected;
    return Card(
      key: ValueKey('activity-${activity.id}'),
      child: Opacity(
        opacity: rejected ? 0.8 : 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserAvatar(name: name),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          'Publicado em ${formatCompetitionDate(activity.submittedAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${ref.watch(scoringServiceProvider).effectiveScore(activity)} pontos',
                        style: AppFonts.numbers(
                          size: 26,
                          color: rejected
                              ? AppColors.textSecondary
                              : AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (rejected)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${activity.score} pontos originais desconsiderados',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.error,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.error,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  StatTile(
                    icon: Icons.route_rounded,
                    value: ActivityInput.formatDistance(activity.distanceKm),
                    caption: 'Distância',
                  ),
                  const SizedBox(width: 8),
                  StatTile(
                    icon: Icons.timer_rounded,
                    value: ActivityInput.formatDuration(
                      activity.durationSeconds,
                    ),
                    caption: 'Duração',
                  ),
                  const SizedBox(width: 8),
                  StatTile(
                    icon: Icons.speed_rounded,
                    value: ActivityInput.formatPace(
                      activity.averagePaceSecondsPerKm,
                    ),
                    caption: 'Ritmo',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        showActivityEvidence(context, activity.evidenceRef),
                    child: EvidenceThumbnail(evidence: activity.evidenceRef),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ModerationPill(status: activity.moderationStatus),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => showActivityEvidence(
                            context,
                            activity.evidenceRef,
                          ),
                          icon: const Icon(Icons.image_rounded, size: 18),
                          label: const Text('Ver evidência'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              ActivitySocialBar(activityId: activity.id),
              ActivityModerationActions(activityId: activity.id),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModerationPill extends StatelessWidget {
  const _ModerationPill({required this.status});
  final ActivityModerationStatus status;
  @override
  Widget build(BuildContext context) => switch (status) {
    ActivityModerationStatus.published => const StatusPill(
      label: 'Publicada',
      color: AppColors.success,
      icon: Icons.check_circle_rounded,
    ),
    ActivityModerationStatus.underReview => const StatusPill(
      label: 'Em revisão',
      color: AppColors.warning,
      icon: Icons.hourglass_top_rounded,
    ),
    ActivityModerationStatus.rejected => const StatusPill(
      label: 'Rejeitada',
      color: AppColors.error,
      icon: Icons.cancel_rounded,
    ),
  };
}
