import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/app/bootstrap/providers.dart';
import 'package:mindurun/core/models/models.dart';
import 'package:mindurun/core/services/demo_seed_service.dart';
import 'package:mindurun/features/moderation/moderation_providers.dart';
import 'package:mindurun/features/ranking/ranking_providers.dart';
import 'package:mindurun/features/session/session_providers.dart';

void main() {
  late ProviderContainer container;
  final now = DateTime(2026, 10, 22, 12);
  void select(String id) => container
      .read(sessionControllerProvider.notifier)
      .selectUser(container.read(userRepositoryProvider).getUser(id)!);
  void fixture({
    List<String> participants = const [
      DemoIds.almir,
      DemoIds.ana,
      DemoIds.carlos,
      DemoIds.joao,
      DemoIds.marina,
    ],
    bool finished = false,
  }) {
    container
        .read(competitionRepositoryProvider)
        .createCompetition(
          Competition(
            id: 'c',
            roomId: DemoIds.room,
            name: 'Moderação',
            startsAt: now.subtract(const Duration(days: 3)),
            endsAt: finished
                ? now.subtract(const Duration(days: 1))
                : now.add(const Duration(days: 1)),
            status: CompetitionStatus.active,
            participantIds: participants,
          ),
        );
    container
        .read(activityRepositoryProvider)
        .createActivity(
          Activity(
            id: 'a',
            competitionId: 'c',
            userId: DemoIds.carlos,
            distanceKm: 7,
            durationSeconds: 2520,
            averagePaceSecondsPerKm: 360,
            evidenceRef: const EvidenceRef.asset('assets/demo/evidence_1.jpg'),
            score: 700,
            moderationStatus: ActivityModerationStatus.published,
            submittedAt: now,
          ),
        );
  }

  setUp(() {
    container = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(() => now)],
    );
    container.read(demoSeedServiceProvider).reset(now);
    select(DemoIds.almir);
  });
  tearDown(() => container.dispose());

  test(
    'report, shared votes, rejection and ranking update without restart',
    () {
      fixture();
      final controller = container.read(moderationControllerProvider.notifier);
      container.listen(rankingForCompetitionProvider('c'), (_, _) {});
      expect(
        container.read(rankingForCompetitionProvider('c')).first.score,
        700,
      );
      final report = controller.reportActivity(
        'a',
        ReportReason.distanceMismatch,
        details: '  A evidência mostra outra distância.  ',
      );
      expect(report.details, 'A evidência mostra outra distância.');
      expect(report.createdAt, now);
      expect(
        container
            .read(activityRepositoryProvider)
            .getActivity('a')!
            .moderationStatus,
        ActivityModerationStatus.underReview,
      );
      expect(
        container.read(rankingForCompetitionProvider('c')).first.score,
        700,
      );
      expect(
        container.read(rankingForCompetitionProvider('c')).first.hasUnderReview,
        isTrue,
      );
      expect(
        container.read(reportsForCompetitionProvider('c')).single.id,
        report.id,
      );
      expect(container.read(minimumVotesForReportProvider(report.id)), 3);
      controller.vote(
        report.id,
        VoteType.invalid,
      ); // Reporter has an ordinary vote.
      expect(
        () => controller.vote(report.id, VoteType.valid),
        throwsStateError,
      );
      expect(container.read(votesForReportProvider(report.id)), hasLength(1));
      select(DemoIds.ana);
      expect(
        container.read(reportByIdProvider(report.id))!.status,
        ReportStatus.open,
      );
      controller.vote(report.id, VoteType.invalid);
      expect(
        container
            .read(activityRepositoryProvider)
            .getActivity('a')!
            .moderationStatus,
        ActivityModerationStatus.underReview,
      );
      select(DemoIds.joao);
      controller.vote(report.id, VoteType.valid);
      expect(
        container.read(reportByIdProvider(report.id))!.status,
        ReportStatus.upheld,
      );
      expect(
        container
            .read(activityRepositoryProvider)
            .getActivity('a')!
            .moderationStatus,
        ActivityModerationStatus.rejected,
      );
      expect(
        container
            .read(rankingForCompetitionProvider('c'))
            .every((e) => e.score == 0),
        isTrue,
      );
      expect(
        container.read(activityRepositoryProvider).getActivity('a')!.score,
        700,
      );
      expect(container.read(votesForReportProvider(report.id)), hasLength(3));
      select(DemoIds.marina);
      expect(
        () => controller.vote(report.id, VoteType.invalid),
        throwsStateError,
      );
      expect(
        () => controller.reportActivity('a', ReportReason.other),
        throwsStateError,
      );
    },
  );

  test('author, nonparticipant, unauthenticated and duplicate reports are rejected', () {
    fixture(participants: [DemoIds.almir, DemoIds.ana, DemoIds.carlos]);
    final controller = container.read(moderationControllerProvider.notifier);
    select(DemoIds.carlos);
    expect(
      () => controller.reportActivity('a', ReportReason.other),
      throwsStateError,
    );
    select(
      DemoIds.marina,
    ); // Still a room member, not a competition participant.
    expect(
      () => controller.reportActivity('a', ReportReason.other),
      throwsStateError,
    );
    select(DemoIds.almir);
    expect(
      () => controller.reportActivity(
        'a',
        ReportReason.other,
        details: 'x' * 501,
      ),
      throwsFormatException,
    );
    final report = controller.reportActivity('a', ReportReason.other);
    expect(report.details, isNull);
    expect(
      () => controller.reportActivity('a', ReportReason.other),
      throwsStateError,
    );
    select(DemoIds.ana);
    expect(
      () => controller.reportActivity('a', ReportReason.other),
      throwsStateError,
    );
    expect(container.read(reportsForActivityProvider('a')), hasLength(1));
    for (final id in [DemoIds.carlos, DemoIds.marina]) {
      select(id);
      expect(
        () => controller.vote(report.id, VoteType.invalid),
        throwsStateError,
      );
    }
    expect(container.read(votesForReportProvider(report.id)), isEmpty);
    container.read(sessionControllerProvider.notifier).logout();
    expect(() => controller.vote(report.id, VoteType.valid), throwsStateError);
    expect(
      () => controller.reportActivity('a', ReportReason.other),
      throwsStateError,
    );
  });

  for (final scenario in [
    (
      'majority keeps',
      [
        DemoIds.almir,
        DemoIds.ana,
        DemoIds.carlos,
        DemoIds.joao,
        DemoIds.marina,
      ],
      [VoteType.invalid, VoteType.valid, VoteType.valid],
      ReportStatus.dismissed,
    ),
    (
      'tie keeps',
      [DemoIds.almir, DemoIds.ana, DemoIds.carlos],
      [VoteType.invalid, VoteType.valid],
      ReportStatus.dismissed,
    ),
    (
      'one voter rejects',
      [DemoIds.almir, DemoIds.carlos],
      [VoteType.invalid],
      ReportStatus.upheld,
    ),
    (
      'one voter keeps',
      [DemoIds.almir, DemoIds.carlos],
      [VoteType.valid],
      ReportStatus.dismissed,
    ),
  ]) {
    test('${scenario.$1}, including finished competition', () {
      fixture(participants: scenario.$2, finished: true);
      final controller = container.read(moderationControllerProvider.notifier);
      final report = controller.reportActivity(
        'a',
        ReportReason.invalidEvidence,
      );
      final voters = [DemoIds.almir, DemoIds.ana, DemoIds.joao];
      for (var i = 0; i < scenario.$3.length; i++) {
        select(voters[i]);
        controller.vote(report.id, scenario.$3[i]);
      }
      expect(
        container.read(reportByIdProvider(report.id))!.status,
        scenario.$4,
      );
      expect(
        container
            .read(activityRepositoryProvider)
            .getActivity('a')!
            .moderationStatus,
        scenario.$4 == ReportStatus.upheld
            ? ActivityModerationStatus.rejected
            : ActivityModerationStatus.published,
      );
      expect(
        container.read(rankingForCompetitionProvider('c')).first.score,
        scenario.$4 == ReportStatus.upheld ? 0 : 700,
      );
      expect(
        container.read(votesForReportProvider(report.id)),
        hasLength(scenario.$3.length),
      );
      select(DemoIds.almir);
      expect(
        () => controller.reportActivity('a', ReportReason.other),
        throwsStateError,
      ); // Same reporter remains blocked by documented rule.
    });
  }
}
