import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_widgets.dart';
import '../../../core/services/activity_input.dart';
import '../../../core/models/models.dart';
import '../../competitions/presentation/competition_widgets.dart';
import '../activity_providers.dart';
import 'evidence_image.dart';
import '../../moderation/presentation/moderation_dialogs.dart';

class CompetitionActivityFeed extends ConsumerWidget {
  const CompetitionActivityFeed({super.key, required this.competitionId});
  final String competitionId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activities = ref.watch(
      activitiesForCompetitionProvider(competitionId),
    );
    final users = ref.watch(userRepositoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Atividades', icon: Icons.dynamic_feed_rounded),
        if (activities.isEmpty)
          const Text('Nenhuma atividade registrada ainda.'),
        for (final activity in activities)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              key: ValueKey('activity-${activity.id}'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        UserAvatar(
                          name:
                              users.getUser(activity.userId)?.displayName ??
                              activity.userId,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                users.getUser(activity.userId)?.displayName ??
                                    activity.userId,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                'Publicado em ${formatCompetitionDate(activity.submittedAt)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ModerationPill(status: activity.moderationStatus),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        StatTile(
                          icon: Icons.straighten_rounded,
                          value: ActivityInput.formatDistance(
                            activity.distanceKm,
                          ),
                          caption: 'Distância',
                        ),
                        const SizedBox(width: 8),
                        StatTile(
                          icon: Icons.timer_outlined,
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
                        Icon(
                          Icons.local_fire_department_rounded,
                          color: theme.colorScheme.tertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${ref.watch(scoringServiceProvider).effectiveScore(activity)} pontos',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color:
                                activity.moderationStatus ==
                                    ActivityModerationStatus.rejected
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    if (activity.moderationStatus ==
                        ActivityModerationStatus.rejected)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${activity.score} pontos originais desconsiderados',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    const Divider(height: 20),
                    Wrap(
                      spacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () => showActivityEvidence(
                            context,
                            activity.evidenceRef,
                          ),
                          icon: const Icon(Icons.image_outlined),
                          label: const Text('Ver evidência'),
                        ),
                        ActivityModerationActions(activityId: activity.id),
                      ],
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

class _ModerationPill extends StatelessWidget {
  const _ModerationPill({required this.status});
  final ActivityModerationStatus status;
  @override
  Widget build(BuildContext context) => switch (status) {
    ActivityModerationStatus.published => const StatusPill(
      label: 'Publicada',
      color: Color(0xFF0B7A55),
      icon: Icons.check_circle_rounded,
    ),
    ActivityModerationStatus.underReview => const StatusPill(
      label: 'Em revisão',
      color: Color(0xFFE65100),
      icon: Icons.hourglass_top_rounded,
    ),
    ActivityModerationStatus.rejected => const StatusPill(
      label: 'Rejeitada',
      color: Color(0xFFC62828),
      icon: Icons.cancel_rounded,
    ),
  };
}
