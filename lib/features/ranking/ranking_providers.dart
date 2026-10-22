import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/bootstrap/providers.dart';
import '../../core/services/domain_services.dart';
import '../activities/activity_providers.dart';
import '../competitions/competition_providers.dart';

/// A derived result, never a separately mutable ranking state.
final rankingForCompetitionProvider =
    Provider.family<List<RankingEntry>, String>((ref, id) {
      final competition = ref.watch(competitionByIdProvider(id));
      if (competition == null) return const [];
      return ref
          .watch(rankingServiceProvider)
          .buildRanking(
            competitionId: competition.id,
            participantIds: competition.participantIds,
            activities: ref.watch(activitiesForCompetitionProvider(id)),
          );
    });

/// Keep the original seed demo using the same per-competition derivation.
final activeRankingProvider = Provider<List<RankingEntry>>((ref) {
  final competition = ref.watch(activeCompetitionProvider);
  if (competition == null) return const [];
  return ref.watch(rankingForCompetitionProvider(competition.id));
});
