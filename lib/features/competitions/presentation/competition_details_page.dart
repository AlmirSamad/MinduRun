import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_widgets.dart';
import '../../activities/presentation/competition_activity_feed.dart';
import '../../session/session_providers.dart';
import '../../ranking/presentation/competition_ranking_section.dart';
import '../../ranking/presentation/competition_result_section.dart';
import '../competition_providers.dart';
import 'competition_widgets.dart';

class CompetitionDetailsPage extends ConsumerWidget {
  const CompetitionDetailsPage({super.key, required this.competitionId});
  final String competitionId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
          icon: const Icon(Icons.arrow_back_rounded),
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
          : RefreshIndicator(
              onRefresh: ref.read(refreshDataProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  HeroCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                competition.name,
                                style: theme.textTheme.headlineSmall,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CompetitionStatusBadge(competition: competition),
                          ],
                        ),
                        const SizedBox(height: 8),
                        CompetitionPeriod(competition: competition),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (canSubmit) ...[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppTheme.controlRadius,
                        ),
                        boxShadow: const [AppTheme.ctaShadow],
                      ),
                      child: FilledButton.icon(
                        style: AppTheme.energyButton(height: 56, fontSize: 18),
                        onPressed: () =>
                            context.push(AppRoutes.newActivity(competitionId)),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Registrar atividade'),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                  if (ref.watch(canJoinCompetitionProvider(competitionId))) ...[
                    FilledButton.icon(
                      key: const Key('join-competition'),
                      style: AppTheme.energyButton(height: 56, fontSize: 18),
                      onPressed: () {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          ref
                              .read(competitionsControllerProvider.notifier)
                              .joinCompetition(competitionId);
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Você agora participa desta competição.',
                              ),
                            ),
                          );
                        } on StateError catch (error) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(error.message)),
                          );
                        }
                      },
                      icon: const Icon(Icons.how_to_reg_rounded),
                      label: const Text('Participar da competição'),
                    ),
                    const SizedBox(height: 28),
                  ],
                  CompetitionResultSection(competitionId: competitionId),
                  CompetitionRankingSection(competitionId: competitionId),
                  const SizedBox(height: 28),
                  Column(
                    key: const Key('competition-participants'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionTitle(
                        'Participantes (${competition.participantIds.length})',
                        icon: Icons.group_rounded,
                      ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final participant in participants)
                                Chip(
                                  avatar: UserAvatar(
                                    name: participant.displayName,
                                    radius: 12,
                                  ),
                                  label: Text(participant.displayName),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  CompetitionActivityFeed(competitionId: competitionId),
                ],
              ),
            ),
    );
  }
}
