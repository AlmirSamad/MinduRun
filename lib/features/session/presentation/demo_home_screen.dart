import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/providers.dart';
import '../../activities/activity_providers.dart';
import '../../competitions/competition_providers.dart';
import '../../ranking/ranking_providers.dart';
import '../../rooms/room_providers.dart';
import '../session_providers.dart';

/// Phase 0 validation screen: confirms seed data, repositories, providers and
/// ranking are wired. Replaced by real flows in later phases.
class DemoHomeScreen extends ConsumerWidget {
  const DemoHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final rooms = ref.watch(currentUserRoomsProvider);
    final competition = ref.watch(activeCompetitionProvider);
    final activities = ref.watch(activeCompetitionActivitiesProvider);
    final ranking = ref.watch(activeRankingProvider);
    final users = ref.watch(userRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Trocar usuário',
            icon: const Icon(Icons.switch_account),
            onPressed: () =>
                ref.read(sessionControllerProvider.notifier).logout(),
          ),
        ],
        title: Text(
          'MinduRun',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('MinduRun Demo', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Resumo dos dados de demonstração',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            children: [
              _InfoRow(
                icon: Icons.person,
                label: 'Usuário atual',
                value: user?.displayName ?? '—',
              ),
              _InfoRow(
                icon: Icons.groups,
                label: 'Sala',
                value: rooms.isEmpty ? '—' : rooms.first.name,
              ),
              _InfoRow(
                icon: Icons.emoji_events,
                label: 'Competição ativa',
                value: competition?.name ?? 'Nenhuma',
              ),
              _InfoRow(
                icon: Icons.directions_run,
                label: 'Participantes',
                value: '${competition?.participantIds.length ?? 0}',
              ),
              _InfoRow(
                icon: Icons.list_alt,
                label: 'Atividades',
                value: '${activities.length}',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Ranking', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (ranking.isEmpty)
            const Text('Sem ranking disponível.')
          else
            _InfoCard(
              children: [
                for (final entry in ranking)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text('${entry.position}')),
                    title: Text(
                      users.getUser(entry.userId)?.displayName ?? entry.userId,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${entry.acceptedDistanceKm.toStringAsFixed(2)} km'
                      '${entry.hasUnderReview ? ' • em revisão' : ''}',
                    ),
                    trailing: Text(
                      '${entry.score} pts',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(children: children),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
