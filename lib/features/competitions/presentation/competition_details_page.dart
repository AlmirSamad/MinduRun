import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/bootstrap/providers.dart';
import '../../activities/presentation/competition_activity_feed.dart';
import '../../session/session_providers.dart';
import '../../ranking/presentation/competition_ranking_section.dart';
import '../competition_providers.dart';
import 'competition_widgets.dart';

class CompetitionDetailsPage extends ConsumerWidget {
  const CompetitionDetailsPage({super.key, required this.competitionId});
  final String competitionId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competition = ref.watch(competitionByIdProvider(competitionId));
    final participants = ref.watch(
      competitionParticipantsProvider(competitionId),
    );
    final canSubmit =
        ref
            .watch(activitySubmissionServiceProvider)
            .authorizationError(
              competition,
              ref.watch(currentUserProvider)?.id,
              ref.watch(clockProvider)(),
            ) ==
        null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da competição'),
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(
                competition == null
                    ? AppRoutes.home
                    : AppRoutes.room(competition.roomId),
              );
            }
          },
        ),
      ),
      body: competition == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Competição não encontrada ou você não participa da sala.',
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  competition.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                const Text('Status'),
                Align(
                  alignment: Alignment.centerLeft,
                  child: CompetitionStatusBadge(competition: competition),
                ),
                const SizedBox(height: 16),
                Text('Período', style: Theme.of(context).textTheme.titleMedium),
                Text('Início: ${formatCompetitionDate(competition.startsAt)}'),
                Text('Término: ${formatCompetitionDate(competition.endsAt)}'),
                const SizedBox(height: 24),
                if (canSubmit) ...[
                  FilledButton.icon(
                    onPressed: () =>
                        context.push(AppRoutes.newActivity(competitionId)),
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar atividade'),
                  ),
                  const SizedBox(height: 16),
                ],
                CompetitionRankingSection(competitionId: competitionId),
                const SizedBox(height: 24),
                Column(
                  key: const Key('competition-participants'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Participantes (${competition.participantIds.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final participant in participants)
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(participant.displayName),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                CompetitionActivityFeed(competitionId: competitionId),
              ],
            ),
    );
  }
}
