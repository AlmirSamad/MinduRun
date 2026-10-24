import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_widgets.dart';
import '../../../core/services/domain_services.dart';
import '../ranking_providers.dart';
import 'competition_ranking_section.dart';

/// Winner and podium of a FINISHED competition (hidden before that).
class CompetitionResultSection extends ConsumerWidget {
  const CompetitionResultSection({super.key, required this.competitionId});
  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(competitionResultProvider(competitionId));
    if (result == null) return const SizedBox.shrink();
    final users = ref.watch(userRepositoryProvider);
    String name(String id) => users.getUser(id)?.displayName ?? id;
    final winners = result.winnerIds.map(name).toList();
    final headline = switch (winners.length) {
      0 => 'Ninguém pontuou nesta competição.',
      1 => 'Campeão: ${winners.single}',
      _ => 'Empate no 1º lugar: ${winners.join(', ')}',
    };
    return Padding(
      key: ValueKey('result-$competitionId'),
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            result.isFinal ? 'Resultado final' : 'Resultado provisório',
            icon: Icons.military_tech_rounded,
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  headline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (result.podium.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _Podium(entries: result.podium, name: name),
                ],
                if (!result.isFinal)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.hourglass_top_rounded,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            result.openReportCount == 1
                                ? '1 denúncia ainda em votação pode alterar o resultado.'
                                : '${result.openReportCount} denúncias ainda em votação podem alterar o resultado.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Columns ordered 2-1-3 with blocks growing on first display.
class _Podium extends StatelessWidget {
  const _Podium({required this.entries, required this.name});
  final List<RankingEntry> entries;
  final String Function(String) name;

  static const _blockHeights = {1: 112.0, 2: 80.0, 3: 56.0};

  @override
  Widget build(BuildContext context) {
    final byPlace = [
      if (entries.length > 1) entries[1],
      entries[0],
      if (entries.length > 2) entries[2],
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final (index, entry) in byPlace.indexed)
          Expanded(
            child: _PodiumColumn(
              entry: entry,
              name: name(entry.userId),
              blockHeight: _blockHeights[entry.position] ?? 56,
              delay: Duration(milliseconds: 80 * index),
            ),
          ),
      ],
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.entry,
    required this.name,
    required this.blockHeight,
    required this.delay,
  });
  final RankingEntry entry;
  final String name;
  final double blockHeight;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final first = entry.position == 1;
    final color = medalColors[entry.position] ?? AppColors.bronze;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          if (first)
            const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.gold,
              size: 22,
            ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: UserAvatar(name: name, radius: first ? 28 : 22),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          Text(
            '${entry.score}',
            style: AppFonts.numbers(size: 18, color: AppColors.accent),
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500) + delay,
            curve: Interval(
              delay.inMilliseconds / (500 + delay.inMilliseconds),
              1,
              curve: Curves.easeOutCubic,
            ),
            builder: (context, t, _) => Container(
              height: blockHeight * t,
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: t < 0.5
                  ? null
                  : Text(
                      '${entry.position}',
                      style: AppFonts.numbers(size: 30, color: AppColors.ink),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
