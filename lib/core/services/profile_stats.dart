import '../models/models.dart';
import 'domain_services.dart';

/// Totals for "Meu perfil", across every competition.
class ProfileStats {
  const ProfileStats({
    required this.activities,
    required this.points,
    required this.acceptedKm,
    required this.rejectedCount,
  });

  /// The user's activities, newest first.
  final List<Activity> activities;

  /// Same rule as the ranking: rejected activities count zero.
  final int points;
  final double acceptedKm;
  final int rejectedCount;
}

class ProfileStatsService {
  const ProfileStatsService({this.scoring = const ScoringService()});
  final ScoringService scoring;

  ProfileStats statsFor(String userId, List<Activity> all) {
    final mine = all.where((a) => a.userId == userId).toList()
      ..sort((a, b) {
        final order = b.submittedAt.compareTo(a.submittedAt);
        return order == 0 ? a.id.compareTo(b.id) : order;
      });
    final accepted = mine.where(
      (a) => a.moderationStatus != ActivityModerationStatus.rejected,
    );
    return ProfileStats(
      activities: List.unmodifiable(mine),
      points: mine.fold(0, (sum, a) => sum + scoring.effectiveScore(a)),
      acceptedKm: accepted.fold(0.0, (sum, a) => sum + a.distanceKm),
      rejectedCount: mine.length - accepted.length,
    );
  }
}
