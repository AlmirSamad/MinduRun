import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_widgets.dart';
import '../../../core/services/activity_input.dart';
import '../../session/session_providers.dart';
import '../ranking_providers.dart';

const medalColors = {
  1: AppColors.gold,
  2: AppColors.silver,
  3: AppColors.bronze,
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
        const SectionTitle('Ranking', icon: Icons.emoji_events_rounded),
        if (entries.isEmpty)
          const EmptyState(
            icon: Icons.emoji_events_rounded,
            message: 'Sem participantes nesta competição.',
          )
        else if (noScore) ...[
          const Text(
            'Ainda não há pontuação nesta competição.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
        ],
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Builder(
              builder: (context) {
                final isMe = entry.userId == user?.id;
                final name =
                    users.getUser(entry.userId)?.displayName ?? entry.userId;
                final medal = noScore ? null : medalColors[entry.position];
                return Card(
                  key: ValueKey('ranking-entry-$competitionId-${entry.userId}'),
                  color: isMe
                      ? Color.alphaBlend(
                          AppColors.accent.withValues(alpha: 0.08),
                          AppColors.surface,
                        )
                      : null,
                  shape: isMe
                      ? RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radius),
                          side: const BorderSide(
                            color: AppColors.accent,
                            width: 2,
                          ),
                        )
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text(
                            '${entry.position}º',
                            style: AppFonts.numbers(
                              color: medal ?? AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          decoration: medal == null
                              ? null
                              : BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: medal, width: 2),
                                ),
                          padding: const EdgeInsets.all(2),
                          child: UserAvatar(name: name, radius: 18),
                        ),
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
                              const SizedBox(height: 4),
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
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (isMe)
                                    const StatusPill(
                                      label: 'Você',
                                      color: AppColors.accent,
                                    ),
                                  if (entry.hasUnderReview)
                                    const StatusPill(
                                      label: 'Em revisão',
                                      color: AppColors.warning,
                                      icon: Icons.hourglass_top_rounded,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${entry.score} pontos',
                              style: AppFonts.numbers(
                                color: isMe
                                    ? AppColors.accent
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
