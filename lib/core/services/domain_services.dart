import '../models/models.dart';

/// Official (single) scoring rule: `score = round(distanceKm * 100)`.
class ScoringService {
  const ScoringService();

  int calculateScore(double distanceKm) {
    if (!distanceKm.isFinite || distanceKm <= 0) return 0;
    return (distanceKm * 100).round();
  }

  /// Points an activity contributes to the ranking.
  /// Rejected activities contribute zero.
  int effectiveScore(Activity activity) =>
      activity.moderationStatus == ActivityModerationStatus.rejected
      ? 0
      : activity.score;
}

/// Result of a pace consistency check.
enum PaceValidationResult {
  valid,
  invalidDistance,
  invalidDuration,
  invalidPace,
  inconsistentPace,
}

/// Checks that the informed pace matches `durationSeconds / distanceKm`.
class PaceValidationService {
  const PaceValidationService({this.toleranceSecondsPerKm = 8});

  final int toleranceSecondsPerKm;

  /// Expected pace in seconds per km (not rounded).
  double expectedPace(double distanceKm, int durationSeconds) =>
      durationSeconds / distanceKm;

  PaceValidationResult validate({
    required double distanceKm,
    required int durationSeconds,
    required int averagePaceSecondsPerKm,
  }) {
    if (!distanceKm.isFinite || distanceKm <= 0) {
      return PaceValidationResult.invalidDistance;
    }
    if (durationSeconds <= 0) return PaceValidationResult.invalidDuration;
    if (averagePaceSecondsPerKm <= 0) return PaceValidationResult.invalidPace;
    final diff =
        (averagePaceSecondsPerKm - expectedPace(distanceKm, durationSeconds))
            .abs();
    return diff <= toleranceSecondsPerKm
        ? PaceValidationResult.valid
        : PaceValidationResult.inconsistentPace;
  }
}

/// Computes the effective competition status from dates and current time.
class CompetitionStateService {
  const CompetitionStateService();

  CompetitionStatus effectiveStatus(Competition competition, DateTime now) {
    if (competition.status == CompetitionStatus.cancelled) {
      return CompetitionStatus.cancelled;
    }
    if (now.isBefore(competition.startsAt)) return CompetitionStatus.scheduled;
    if (now.isBefore(competition.endsAt)) return CompetitionStatus.active;
    return CompetitionStatus.finished;
  }

  bool acceptsSubmissions(Competition competition, DateTime now) =>
      effectiveStatus(competition, now) == CompetitionStatus.active;
}

/// One row of a derived ranking.
class RankingEntry {
  const RankingEntry({
    required this.position,
    required this.userId,
    required this.score,
    required this.acceptedDistanceKm,
    required this.activityCount,
    required this.underReviewCount,
  });

  final int position;
  final String userId;
  final int score;
  final double acceptedDistanceKm;
  final int activityCount;
  final int underReviewCount;

  bool get hasUnderReview => underReviewCount > 0;
}

/// Derives the ranking from activities (never stored as source of truth).
class RankingService {
  const RankingService({this.scoring = const ScoringService()});

  final ScoringService scoring;

  /// Tie-break: higher score, then greater accepted distance, then the
  /// order of [participantIds] (stable). Positions are sequential ordinals
  /// after these tie-breaks, including otherwise identical participants.
  List<RankingEntry> buildRanking({
    required String competitionId,
    required List<String> participantIds,
    required List<Activity> activities,
  }) {
    final score = <String, int>{for (final id in participantIds) id: 0};
    final distance = <String, double>{for (final id in participantIds) id: 0};
    final count = <String, int>{for (final id in participantIds) id: 0};
    final review = <String, int>{for (final id in participantIds) id: 0};

    for (final a in activities) {
      if (a.competitionId != competitionId) continue;
      if (!score.containsKey(a.userId)) continue;
      count[a.userId] = count[a.userId]! + 1;
      if (a.moderationStatus == ActivityModerationStatus.rejected) continue;
      score[a.userId] = score[a.userId]! + scoring.effectiveScore(a);
      distance[a.userId] = distance[a.userId]! + a.distanceKm;
      if (a.moderationStatus == ActivityModerationStatus.underReview) {
        review[a.userId] = review[a.userId]! + 1;
      }
    }

    final order = {
      for (var i = 0; i < participantIds.length; i++) participantIds[i]: i,
    };
    final ids = score.keys.toList()
      ..sort((a, b) {
        final byScore = score[b]!.compareTo(score[a]!);
        if (byScore != 0) return byScore;
        final byDistance = distance[b]!.compareTo(distance[a]!);
        if (byDistance != 0) return byDistance;
        return order[a]!.compareTo(order[b]!);
      });

    return [
      for (var i = 0; i < ids.length; i++)
        RankingEntry(
          position: i + 1,
          userId: ids[i],
          score: score[ids[i]]!,
          acceptedDistanceKm: distance[ids[i]]!,
          activityCount: count[ids[i]]!,
          underReviewCount: review[ids[i]]!,
        ),
    ];
  }
}

/// Outcome of evaluating votes on a report.
enum ModerationOutcome { pending, keepValid, reject }

/// Pure moderation rules (eligibility and vote counting).
class ModerationService {
  const ModerationService();

  /// The author cannot report own activity; one report per user/activity;
  /// reporter must be a competition participant.
  bool canReport({
    required Activity activity,
    required String reporterUserId,
    required List<String> participantIds,
    required List<ActivityReport> existingReports,
  }) {
    if (activity.userId == reporterUserId) return false;
    if (!participantIds.contains(reporterUserId)) return false;
    if (activity.moderationStatus != ActivityModerationStatus.published) {
      return false;
    }
    return !existingReports.any(
      (r) =>
          r.activityId == activity.id &&
          (r.status == ReportStatus.open || r.reporterUserId == reporterUserId),
    );
  }

  bool canVote({
    required Activity activity,
    required ActivityReport report,
    required String voterUserId,
    required List<String> participantIds,
    required List<ReportVote> votes,
  }) =>
      report.activityId == activity.id &&
      report.status == ReportStatus.open &&
      activity.moderationStatus == ActivityModerationStatus.underReview &&
      eligibleVoters(
        activity: activity,
        participantIds: participantIds,
      ).contains(voterUserId) &&
      !votes.any(
        (v) => v.reportId == report.id && v.voterUserId == voterUserId,
      );

  static const maxDetailsLength = 500;

  /// Eligible voters: other competition participants (not the author).
  List<String> eligibleVoters({
    required Activity activity,
    required List<String> participantIds,
  }) => participantIds.where((id) => id != activity.userId).toSet().toList();

  int minimumVotes(int eligibleVoterCount) => eligibleVoterCount <= 0
      ? 0
      : (eligibleVoterCount < 3 ? eligibleVoterCount : 3);

  /// After minimum votes, strict majority decides; tie keeps activity valid.
  ModerationOutcome evaluate({
    required List<ReportVote> votes,
    required int eligibleVoterCount,
  }) {
    if (eligibleVoterCount <= 0 ||
        votes.length < minimumVotes(eligibleVoterCount) ||
        votes.isEmpty) {
      return ModerationOutcome.pending;
    }
    final invalid = votes.where((v) => v.vote == VoteType.invalid).length;
    final valid = votes.length - invalid;
    return invalid > valid
        ? ModerationOutcome.reject
        : ModerationOutcome.keepValid;
  }
}
