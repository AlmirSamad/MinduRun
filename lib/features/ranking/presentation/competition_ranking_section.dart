import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../core/services/activity_input.dart';
import '../../session/session_providers.dart';
import '../ranking_providers.dart';

class CompetitionRankingSection extends ConsumerWidget {
  const CompetitionRankingSection({super.key, required this.competitionId});
  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(rankingForCompetitionProvider(competitionId));
    final user = ref.watch(currentUserProvider);
    final users = ref.watch(userRepositoryProvider);
    final theme = Theme.of(context);
    return Column(
      key: ValueKey('ranking-$competitionId'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Ranking', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        if (entries.isEmpty)
          const Text('Sem participantes nesta competição.')
        else if (entries.every((entry) => entry.score == 0)) ...[
          const Text('Ainda não há pontuação nesta competição.'),
          const SizedBox(height: 8),
        ],
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              key: ValueKey('ranking-entry-$competitionId-${entry.userId}'),
              color: entry.userId == user?.id
                  ? theme.colorScheme.secondaryContainer
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${entry.position}º',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            users.getUser(entry.userId)?.displayName ??
                                entry.userId,
                            style: theme.textTheme.titleMedium,
                          ),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              Text('${entry.score} pontos'),
                              Text(
                                ActivityInput.formatDistance(
                                  entry.acceptedDistanceKm,
                                ),
                              ),
                              if (entry.userId == user?.id) const Text('Você'),
                              if (entry.hasUnderReview)
                                const Text('Em revisão'),
                            ],
                          ),
                        ],
                      ),
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
