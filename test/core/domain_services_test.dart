import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/core/models/models.dart';
import 'package:mindurun/core/services/domain_services.dart';

Activity _activity(
  String id,
  String userId,
  double km, {
  ActivityModerationStatus status = ActivityModerationStatus.published,
}) => Activity(
  id: id,
  competitionId: 'c1',
  userId: userId,
  distanceKm: km,
  durationSeconds: (km * 360).round(),
  averagePaceSecondsPerKm: 360,
  evidenceRef: const EvidenceRef.asset('assets/demo/evidence_1.jpg'),
  score: const ScoringService().calculateScore(km),
  moderationStatus: status,
  submittedAt: DateTime(2026),
);

void main() {
  group('ScoringService', () {
    const s = ScoringService();
    test('round(distanceKm * 100)', () {
      expect(s.calculateScore(3.00), 300);
      expect(s.calculateScore(5.00), 500);
      expect(s.calculateScore(5.23), 523);
      expect(s.calculateScore(10.00), 1000);
    });
    test('invalid distance scores zero', () {
      expect(s.calculateScore(0), 0);
      expect(s.calculateScore(-1), 0);
      expect(s.calculateScore(double.nan), 0);
    });
    test('rejected activity has zero effective score', () {
      final a = _activity(
        'a',
        'u',
        5,
        status: ActivityModerationStatus.rejected,
      );
      expect(s.effectiveScore(a), 0);
    });
  });

  group('PaceValidationService', () {
    const p = PaceValidationService();
    PaceValidationResult check(double km, int sec, int pace) => p.validate(
      distanceKm: km,
      durationSeconds: sec,
      averagePaceSecondsPerKm: pace,
    );

    test('exact pace is valid', () {
      expect(check(5, 1800, 360), PaceValidationResult.valid);
    });
    test('within ±8 s/km is valid', () {
      expect(check(5, 1800, 368), PaceValidationResult.valid);
      expect(check(5, 1800, 352), PaceValidationResult.valid);
    });
    test('outside tolerance is inconsistent', () {
      expect(check(5, 1800, 369), PaceValidationResult.inconsistentPace);
      expect(check(5, 1800, 351), PaceValidationResult.inconsistentPace);
      expect(check(5, 1800, 340), PaceValidationResult.inconsistentPace);
    });
    test('non-positive values are rejected', () {
      expect(check(0, 1800, 360), PaceValidationResult.invalidDistance);
      expect(check(5, 0, 360), PaceValidationResult.invalidDuration);
      expect(check(5, 1800, 0), PaceValidationResult.invalidPace);
    });
  });

  group('CompetitionStateService', () {
    const svc = CompetitionStateService();
    final now = DateTime(2026, 10, 22, 12);
    Competition comp(DateTime start, DateTime end, [CompetitionStatus? s]) =>
        Competition(
          id: 'c',
          roomId: 'r',
          name: 'C',
          startsAt: start,
          endsAt: end,
          status: s ?? CompetitionStatus.active,
          participantIds: const [],
        );
    const day = Duration(days: 1);

    test('scheduled', () {
      expect(
        svc.effectiveStatus(comp(now.add(day), now.add(day * 2)), now),
        CompetitionStatus.scheduled,
      );
    });
    test('active', () {
      final c = comp(now.subtract(day), now.add(day));
      expect(svc.effectiveStatus(c, now), CompetitionStatus.active);
      expect(svc.acceptsSubmissions(c, now), isTrue);
    });
    test('finished', () {
      final c = comp(now.subtract(day * 2), now.subtract(day));
      expect(svc.effectiveStatus(c, now), CompetitionStatus.finished);
      expect(svc.acceptsSubmissions(c, now), isFalse);
    });
    test('exact start is active and exact end is finished regardless of stored status', () {
      final c = comp(now, now.add(day), CompetitionStatus.scheduled);
      expect(
        svc.effectiveStatus(c, now.subtract(const Duration(microseconds: 1))),
        CompetitionStatus.scheduled,
      );
      expect(svc.effectiveStatus(c, c.startsAt), CompetitionStatus.active);
      expect(svc.effectiveStatus(c, c.endsAt), CompetitionStatus.finished);
    });
    test('cancelled overrides dates', () {
      final c = comp(
        now.subtract(day),
        now.add(day),
        CompetitionStatus.cancelled,
      );
      expect(svc.effectiveStatus(c, now), CompetitionStatus.cancelled);
    });
  });

  group('RankingService', () {
    const r = RankingService();

    test('orders by score and includes participants without activities', () {
      final ranking = r.buildRanking(
        competitionId: 'c1',
        participantIds: ['a', 'b', 'c'],
        activities: [_activity('1', 'a', 3), _activity('2', 'b', 5)],
      );
      expect(ranking.map((e) => e.userId), ['b', 'a', 'c']);
      expect(ranking.map((e) => e.score), [500, 300, 0]);
      expect(ranking.map((e) => e.position), [1, 2, 3]);
    });

    test('rejected counts zero; under review still counts', () {
      final ranking = r.buildRanking(
        competitionId: 'c1',
        participantIds: ['a', 'b'],
        activities: [
          _activity('1', 'a', 10, status: ActivityModerationStatus.rejected),
          _activity('2', 'b', 2, status: ActivityModerationStatus.underReview),
        ],
      );
      expect(ranking.first.userId, 'b');
      expect(ranking.first.score, 200);
      expect(ranking.first.hasUnderReview, isTrue);
      expect(ranking.last.score, 0);
      expect(ranking.last.acceptedDistanceKm, 0);
    });

    test('tie-break by accepted distance', () {
      // Same score (500) but different accepted distance (5.004 vs 4.996).
      final ranking = r.buildRanking(
        competitionId: 'c1',
        participantIds: ['a', 'b'],
        activities: [_activity('1', 'a', 4.996), _activity('2', 'b', 5.004)],
      );
      expect(ranking.map((e) => e.score), [500, 500]);
      expect(ranking.first.userId, 'b');
    });

    test('tie-break by stable participant order', () {
      final ranking = r.buildRanking(
        competitionId: 'c1',
        participantIds: ['b', 'a'],
        activities: [_activity('1', 'a', 5), _activity('2', 'b', 5)],
      );
      expect(ranking.map((e) => e.userId), ['b', 'a']);
    });
  });

  group('ModerationService', () {
    const m = ModerationService();
    final activity = _activity('1', 'a', 5);
    ReportVote vote(String user, VoteType t) => ReportVote(
      id: user,
      reportId: 'r',
      voterUserId: user,
      vote: t,
      createdAt: DateTime(2026),
    );

    test('author cannot report own activity; duplicates blocked', () {
      final participants = ['a', 'b', 'c'];
      expect(
        m.canReport(
          activity: activity,
          reporterUserId: 'a',
          participantIds: participants,
          existingReports: const [],
        ),
        isFalse,
      );
      final existing = ActivityReport(
        id: 'r',
        activityId: '1',
        reporterUserId: 'b',
        reason: ReportReason.other,
        status: ReportStatus.open,
        createdAt: DateTime(2026),
      );
      expect(
        m.canReport(
          activity: activity,
          reporterUserId: 'b',
          participantIds: participants,
          existingReports: [existing],
        ),
        isFalse,
      );
      expect(
        m.canReport(
          activity: activity,
          reporterUserId: 'c',
          participantIds: participants,
          existingReports: [existing],
        ),
        isFalse,
      );
    });

    test('minimum votes, majority and tie', () {
      expect(m.minimumVotes(5), 3);
      expect(m.minimumVotes(2), 2);
      expect(
        m.evaluate(votes: [vote('b', VoteType.invalid)], eligibleVoterCount: 4),
        ModerationOutcome.pending,
      );
      expect(
        m.evaluate(
          votes: [
            vote('b', VoteType.invalid),
            vote('c', VoteType.invalid),
            vote('d', VoteType.valid),
          ],
          eligibleVoterCount: 4,
        ),
        ModerationOutcome.reject,
      );
      expect(
        m.evaluate(
          votes: [vote('b', VoteType.invalid), vote('c', VoteType.valid)],
          eligibleVoterCount: 2,
        ),
        ModerationOutcome.keepValid,
      );
    });
  });
}
