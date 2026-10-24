import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/bootstrap/providers.dart';
import '../../core/services/domain_services.dart';
import '../activities/activity_providers.dart';
import '../../core/models/models.dart';
import '../competitions/competition_providers.dart';
import '../moderation/moderation_providers.dart';

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

/// Winner/podium once the competition is FINISHED; null before that.
/// Auto-dispose: the end depends on the clock, which does not notify, so the
/// result is recomputed whenever the page is opened again.
final competitionResultProvider = Provider.autoDispose
    .family<CompetitionResult?, String>((ref, id) {
      final competition = ref.watch(competitionByIdProvider(id));
      if (competition == null) return null;
      final now = ref.watch(clockProvider)();
      // Depend on ranking/moderation only once finished: running competitions
      // never pay for (or react through) this provider.
      if (ref
              .watch(competitionStateServiceProvider)
              .effectiveStatus(competition, now) !=
          CompetitionStatus.finished) {
        return null;
      }
      final ranking = ref.watch(rankingForCompetitionProvider(id));
      ref.watch(moderationControllerProvider);
      final activityIds = ref
          .read(activityRepositoryProvider)
          .listCompetitionActivities(id)
          .map((a) => a.id)
          .toSet();
      final openReports = ref
          .read(moderationRepositoryProvider)
          .listReports()
          .where(
            (r) =>
                r.status == ReportStatus.open &&
                activityIds.contains(r.activityId),
          )
          .length;
      return ref
          .watch(competitionResultServiceProvider)
          .result(
            competition: competition,
            now: now,
            ranking: ranking,
            openReportCount: openReports,
          );
    });

/// Keep the original seed demo using the same per-competition derivation.
final activeRankingProvider = Provider<List<RankingEntry>>((ref) {
  final competition = ref.watch(activeCompetitionProvider);
  if (competition == null) return const [];
  return ref.watch(rankingForCompetitionProvider(competition.id));
});
