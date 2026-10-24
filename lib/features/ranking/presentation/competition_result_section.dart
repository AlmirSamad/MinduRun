import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_widgets.dart';
import '../ranking_providers.dart';

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
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            result.isFinal ? 'Resultado final' : 'Resultado provisório',
            icon: Icons.emoji_events_rounded,
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final entry in result.podium)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${entry.position}º ${name(entry.userId)} — ${entry.score} pontos',
                      ),
                    ),
                  if (!result.isFinal)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        result.openReportCount == 1
                            ? '1 denúncia ainda em votação pode alterar o resultado.'
                            : '${result.openReportCount} denúncias ainda em votação podem alterar o resultado.',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
