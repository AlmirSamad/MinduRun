import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/core/models/models.dart';
import 'package:mindurun/core/remote/remote_store.dart';

void main() {
  test('activity survives a row round trip', () {
    final activity = Activity(
      id: 'activity-1',
      competitionId: 'c1',
      userId: 'u1',
      distanceKm: 5.23,
      durationSeconds: 1830,
      averagePaceSecondsPerKm: 350,
      evidenceRef: const EvidenceRef(
        id: 'u1/evidence-1.jpg',
        kind: EvidenceKind.remote,
      ),
      score: 523,
      moderationStatus: ActivityModerationStatus.underReview,
      submittedAt: DateTime.utc(2026, 10, 30, 9),
    );
    final row = RemoteRows.activityRow(activity);
    expect(row['moderation_status'], 'underReview');
    final back = RemoteRows.activity(row);
    expect(back.evidenceRef, activity.evidenceRef);
    expect(back.moderationStatus, ActivityModerationStatus.underReview);
    expect(back.submittedAt.isAtSameMomentAs(activity.submittedAt), isTrue);
    expect(back.distanceKm, 5.23);
  });

  test('rooms collect members in join order', () {
    final rooms = RemoteRows.rooms(
      [
        {
          'id': 'r1',
          'name': 'Sala',
          'owner_id': 'u1',
          'invite_code': 'ABC234',
          'created_at': '2026-10-23T12:00:00Z',
        },
      ],
      [
        {'room_id': 'r1', 'user_id': 'u1'},
        {'room_id': 'r1', 'user_id': 'u2'},
      ],
    );
    expect(rooms.single.memberIds, ['u1', 'u2']);
  });

  test('competition, report and vote rows round trip', () {
    final competition = Competition(
      id: 'c1',
      roomId: 'r1',
      name: 'Desafio',
      startsAt: DateTime.utc(2026, 10, 30),
      endsAt: DateTime.utc(2026, 11, 6),
      status: CompetitionStatus.active,
      participantIds: const ['u1', 'u2'],
    );
    final c = RemoteRows.competition(RemoteRows.competitionRow(competition));
    expect(c.participantIds, ['u1', 'u2']);
    expect(c.status, CompetitionStatus.active);

    final report = ActivityReport(
      id: 'rep1',
      activityId: 'a1',
      reporterUserId: 'u2',
      reason: ReportReason.suspectedOtherPersonActivity,
      status: ReportStatus.open,
      createdAt: DateTime.utc(2026, 10, 30),
    );
    final r = RemoteRows.report(RemoteRows.reportRow(report));
    expect(r.reason, ReportReason.suspectedOtherPersonActivity);
    expect(r.details, isNull);

    final vote = ReportVote(
      id: 'v1',
      reportId: 'rep1',
      voterUserId: 'u3',
      vote: VoteType.invalid,
      createdAt: DateTime.utc(2026, 10, 30),
    );
    expect(RemoteRows.vote(RemoteRows.voteRow(vote)).vote, VoteType.invalid);
  });
}
