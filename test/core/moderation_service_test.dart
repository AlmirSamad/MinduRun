import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/core/models/models.dart';
import 'package:mindurun/core/services/domain_services.dart';
import 'package:mindurun/core/repositories/in_memory_repositories.dart';

void main() {
  const service = ModerationService();
  final now = DateTime(2026);
  final activity = Activity(
    id: 'a',
    competitionId: 'c',
    userId: 'author',
    distanceKm: 5,
    durationSeconds: 1800,
    averagePaceSecondsPerKm: 360,
    evidenceRef: const EvidenceRef.asset('e'),
    score: 500,
    moderationStatus: ActivityModerationStatus.published,
    submittedAt: now,
  );
  ActivityReport report({
    String id = 'r',
    ReportStatus status = ReportStatus.open,
  }) => ActivityReport(
    id: id,
    activityId: 'a',
    reporterUserId: 'reporter',
    reason: ReportReason.other,
    status: status,
    createdAt: now,
  );
  ReportVote vote(String voter, {String id = 'v'}) => ReportVote(
    id: id,
    reportId: 'r',
    voterUserId: voter,
    vote: VoteType.invalid,
    createdAt: now,
  );
  test('report eligibility, active report and rejection guards', () {
    for (final entry in [
      ('author', false),
      ('outsider', false),
      ('reporter', true),
    ]) {
      expect(
        service.canReport(
          activity: activity,
          reporterUserId: entry.$1,
          participantIds: ['author', 'reporter'],
          existingReports: [],
        ),
        entry.$2,
      );
    }
    expect(
      service.canReport(
        activity: activity,
        reporterUserId: 'other',
        participantIds: ['other'],
        existingReports: [report()],
      ),
      isFalse,
    );
    expect(
      service.canReport(
        activity: activity.copyWith(
          moderationStatus: ActivityModerationStatus.rejected,
        ),
        reporterUserId: 'reporter',
        participantIds: ['reporter'],
        existingReports: [],
      ),
      isFalse,
    );
  });
  test('vote eligibility includes reporter, excludes author, outsider, duplicates and resolved reports', () {
    final review = activity.copyWith(
      moderationStatus: ActivityModerationStatus.underReview,
    );
    bool allowed(
      String user, {
      List<ReportVote> votes = const [],
      ReportStatus status = ReportStatus.open,
    }) => service.canVote(
      activity: review,
      report: report(status: status),
      voterUserId: user,
      participantIds: ['author', 'reporter', 'other'],
      votes: votes,
    );
    expect(allowed('reporter'), isTrue);
    expect(allowed('other'), isTrue);
    expect(allowed('author'), isFalse);
    expect(allowed('outsider'), isFalse);
    expect(allowed('reporter', votes: [vote('reporter')]), isFalse);
    expect(allowed('other', status: ReportStatus.dismissed), isFalse);
    expect(allowed('other', status: ReportStatus.upheld), isFalse);
  });
  test('minimum votes follows available voters, zero stays pending', () {
    for (final entry in [(4, 3), (3, 3), (2, 2), (1, 1), (0, 0)]) {
      expect(service.minimumVotes(entry.$1), entry.$2);
    }
    expect(
      service.evaluate(votes: [], eligibleVoterCount: 0),
      ModerationOutcome.pending,
    );
    expect(
      service.evaluate(votes: [vote('x')], eligibleVoterCount: 0),
      ModerationOutcome.pending,
    );
  });
  test(
    'repository enforces immutable votes, one open report and final history',
    () {
      final repo = InMemoryModerationRepository();
      addTearDown(repo.dispose);
      repo.createReport(report());
      expect(
        () => repo.createReport(report(id: 'duplicate')),
        throwsStateError,
      );
      repo.addVote(vote('reporter'));
      expect(
        () => repo.addVote(vote('reporter', id: 'other')),
        throwsStateError,
      );
      expect(repo.listReportVotes('r'), hasLength(1));
      repo.resolveReport('r', ReportStatus.upheld);
      expect(() => repo.addVote(vote('other', id: 'other')), throwsStateError);
      expect(
        () => repo.resolveReport('r', ReportStatus.dismissed),
        throwsStateError,
      );
      expect(repo.listActivityReports('a').single.status, ReportStatus.upheld);
      expect(repo.listReportVotes('r').single.vote, VoteType.invalid);
    },
  );
}
