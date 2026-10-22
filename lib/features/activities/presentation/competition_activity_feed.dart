import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/providers.dart';
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
    final activities = ref.watch(
      activitiesForCompetitionProvider(competitionId),
    );
    final users = ref.watch(userRepositoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Atividades', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (activities.isEmpty)
          const Text('Nenhuma atividade registrada ainda.'),
        for (final activity in activities)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              key: ValueKey('activity-${activity.id}'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      users.getUser(activity.userId)?.displayName ??
                          activity.userId,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(ActivityInput.formatDistance(activity.distanceKm)),
                    Text(
                      'Duração: ${ActivityInput.formatDuration(activity.durationSeconds)}',
                    ),
                    Text(
                      'Ritmo: ${ActivityInput.formatPace(activity.averagePaceSecondsPerKm)}',
                    ),
                    Text(
                      '${ref.watch(scoringServiceProvider).effectiveScore(activity)} pontos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (activity.moderationStatus ==
                        ActivityModerationStatus.published)
                      const Text('Publicada'),
                    if (activity.moderationStatus ==
                        ActivityModerationStatus.underReview)
                      const Text('Em revisão'),
                    if (activity.moderationStatus ==
                        ActivityModerationStatus.rejected)
                      Text(
                        'Rejeitada • ${activity.score} pontos originais desconsiderados',
                      ),
                    Text(
                      'Publicado em ${formatCompetitionDate(activity.submittedAt)}',
                    ),
                    TextButton(
                      onPressed: () =>
                          showActivityEvidence(context, activity.evidenceRef),
                      child: const Text('Ver evidência'),
                    ),
                    ActivityModerationActions(activityId: activity.id),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
