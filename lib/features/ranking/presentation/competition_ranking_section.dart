import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_widgets.dart';
import '../../../core/services/activity_input.dart';
import '../../session/session_providers.dart';
import '../ranking_providers.dart';

const _medalColors = {
  1: Color(0xFFF5B301),
  2: Color(0xFF9EA7AD),
  3: Color(0xFFCD7F32),
};

class CompetitionRankingSection extends ConsumerWidget {
  const CompetitionRankingSection({super.key, required this.competitionId});
  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(rankingForCompetitionProvider(competitionId));
    final user = ref.watch(currentUserProvider);
    final users = ref.watch(userRepositoryProvider);
    final theme = Theme.of(context);
    final noScore = entries.every((entry) => entry.score == 0);
    return Column(
      key: ValueKey('ranking-$competitionId'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Ranking', icon: Icons.leaderboard_rounded),
        if (entries.isEmpty)
          const Text('Sem participantes nesta competição.')
        else if (noScore) ...[
          const Text('Ainda não há pontuação nesta competição.'),
          const SizedBox(height: 8),
        ],
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              key: ValueKey('ranking-entry-$competitionId-${entry.userId}'),
              color: entry.userId == user?.id
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.6)
                  : null,
              shape: entry.userId == user?.id
                  ? RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                    )
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    _PositionBadge(
                      position: entry.position,
                      medal: noScore ? null : _medalColors[entry.position],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            users.getUser(entry.userId)?.displayName ??
                                entry.userId,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                ActivityInput.formatDistance(
                                  entry.acceptedDistanceKm,
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (entry.userId == user?.id)
                                StatusPill(
                                  label: 'Você',
                                  color: theme.colorScheme.primary,
                                ),
                              if (entry.hasUnderReview)
                                const StatusPill(
                                  label: 'Em revisão',
                                  color: Color(0xFFE65100),
                                  icon: Icons.hourglass_top_rounded,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.score} pontos',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
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

class _PositionBadge extends StatelessWidget {
  const _PositionBadge({required this.position, required this.medal});
  final int position;
  final Color? medal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = medal;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color ?? theme.colorScheme.surfaceContainerHigh,
        boxShadow: color == null
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Text(
        '$positionº',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: color == null
              ? theme.colorScheme.onSurfaceVariant
              : Colors.white,
        ),
      ),
    );
  }
}
