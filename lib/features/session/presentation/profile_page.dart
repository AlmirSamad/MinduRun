import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_widgets.dart';
import '../../../core/models/models.dart';
import '../../../core/services/activity_input.dart';
import '../../competitions/presentation/competition_widgets.dart';
import '../../social/social_providers.dart';
import '../session_providers.dart';

/// "Meu perfil": totals and every activity of the current user.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final stats = ref.watch(profileStatsProvider);
    final competitions = ref.watch(competitionRepositoryProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu perfil'),
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
      ),
      body: stats == null || user == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Row(
                  children: [
                    UserAvatar(name: user.displayName, radius: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        user.displayName,
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${stats.points} pontos',
                          key: const Key('profile-points'),
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          '${ActivityInput.formatDistance(stats.acceptedKm)} válidos em ${stats.activities.length} atividades',
                        ),
                        if (stats.rejectedCount > 0)
                          Text(
                            '${stats.rejectedCount} rejeitada(s) na votação',
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const SectionTitle('Minhas atividades', icon: Icons.history),
                if (stats.activities.isEmpty)
                  const Text('Você ainda não registrou atividades.'),
                for (final activity in stats.activities)
                  Card(
                    child: ListTile(
                      title: Text(
                        competitions
                                .getCompetition(activity.competitionId)
                                ?.name ??
                            'Competição',
                      ),
                      subtitle: Text(
                        '${ActivityInput.formatDistance(activity.distanceKm)} · '
                        '${formatCompetitionDate(activity.submittedAt)} · '
                        '${_statusLabel(activity.moderationStatus)}',
                      ),
                      trailing: Text(
                        '${ref.watch(scoringServiceProvider).effectiveScore(activity)} pts',
                      ),
                      onTap: () => context.push(
                        AppRoutes.competition(activity.competitionId),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  static String _statusLabel(ActivityModerationStatus status) =>
      switch (status) {
        ActivityModerationStatus.published => 'Publicada',
        ActivityModerationStatus.underReview => 'Em revisão',
        ActivityModerationStatus.rejected => 'Rejeitada',
      };
}
