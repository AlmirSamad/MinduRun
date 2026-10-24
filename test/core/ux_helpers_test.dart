import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/core/models/models.dart';
import 'package:mindurun/core/services/activity_input.dart';
import 'package:mindurun/core/services/competition_countdown.dart';
import 'package:mindurun/core/services/pending_actions_service.dart';
import 'package:mindurun/core/services/room_rules.dart';
import 'package:mindurun/features/home/presentation/home_widgets.dart';

void main() {
  group('ActivityInput.suggestPace', () {
    test('derives MM:SS pace from distance and duration', () {
      expect(ActivityInput.suggestPace('5,23', '31:45'), '06:04');
      expect(ActivityInput.suggestPace('10', '1:00:00'), '06:00');
      expect(ActivityInput.suggestPace('0.5', '45:00'), '90:00');
    });

    test('waits for both values to be valid', () {
      expect(ActivityInput.suggestPace('', '31:45'), isNull);
      expect(ActivityInput.suggestPace('5', '31:7'), isNull);
      expect(ActivityInput.suggestPace('0', '31:45'), isNull);
    });

    test('suggested pace always passes the consistency rule', () {
      final pace = ActivityInput.suggestPace('7,1', '42:36')!;
      expect(ActivityInput.parsePace(pace), closeTo(2556 / 7.1, 8));
    });
  });

  group('competitionCountdown', () {
    final start = DateTime(2026, 10, 30, 8);
    final competition = Competition(
      id: 'c1',
      roomId: 'r1',
      name: 'Desafio',
      startsAt: start,
      endsAt: start.add(const Duration(days: 7)),
      status: CompetitionStatus.scheduled,
      participantIds: const [],
    );

    test('scheduled, active, last day and finished', () {
      expect(
        competitionCountdown(
          competition,
          start.subtract(const Duration(hours: 2, minutes: 30)),
        ),
        'Começa em 3 h',
      );
      expect(
        competitionCountdown(competition, start.add(const Duration(days: 1))),
        'Termina em 6 dias',
      );
      expect(
        competitionCountdown(
          competition,
          start.add(const Duration(days: 6, hours: 19)),
        ),
        'Último dia! Termina em 5 h',
      );
      expect(
        competitionCountdown(
          competition,
          start.add(const Duration(days: 6, hours: 23, minutes: 50)),
        ),
        'Último dia! Termina em 10 min',
      );
      expect(
        competitionCountdown(competition, start.add(const Duration(days: 8))),
        'Encerrada',
      );
    });

    test('cancelled competitions have no countdown', () {
      expect(
        competitionCountdown(
          competition.copyWith(status: CompetitionStatus.cancelled),
          start,
        ),
        isNull,
      );
    });
  });

  test('invite message carries the code and the deep link', () {
    final text = RoomRules.inviteMessage(
      roomName: 'Corrida do Mindu',
      inviteCode: 'abc234',
    );
    expect(text, contains('"Corrida do Mindu"'));
    expect(text, contains('use: abc234'));
    expect(text, contains('mindurun://open/join/ABC234'));
  });

  test('sync age label', () {
    final now = DateTime(2026, 10, 30, 12);
    expect(syncAgeLabel(null, now), 'Ainda não sincronizado');
    expect(syncAgeLabel(now, now), startsWith('Atualizado agora'));
    expect(
      syncAgeLabel(now.subtract(const Duration(seconds: 40)), now),
      startsWith('Atualizado há 40 s'),
    );
    expect(
      syncAgeLabel(now.subtract(const Duration(minutes: 3)), now),
      startsWith('Atualizado há 3 min'),
    );
  });

  group('PendingActionsService', () {
    final now = DateTime(2026, 10, 30, 12);
    final room = Room(
      id: 'r1',
      name: 'Sala',
      ownerUserId: 'a',
      inviteCode: 'ABC234',
      memberIds: const ['a', 'b', 'c', 'late'],
      createdAt: now,
    );
    final competition = Competition(
      id: 'c1',
      roomId: 'r1',
      name: 'Desafio',
      startsAt: now.subtract(const Duration(days: 1)),
      endsAt: now.add(const Duration(days: 6)),
      status: CompetitionStatus.active,
      participantIds: const ['a', 'b', 'c'],
    );
    final activity = Activity(
      id: 'act',
      competitionId: 'c1',
      userId: 'a',
      distanceKm: 5,
      durationSeconds: 1800,
      averagePaceSecondsPerKm: 360,
      evidenceRef: const EvidenceRef.asset('x'),
      score: 500,
      moderationStatus: ActivityModerationStatus.underReview,
      submittedAt: now,
    );
    final report = ActivityReport(
      id: 'rep',
      activityId: 'act',
      reporterUserId: 'b',
      reason: ReportReason.other,
      status: ReportStatus.open,
      createdAt: now,
    );

    List<PendingAction> pending(
      String user, {
      List<ReportVote> votes = const [],
    }) => const PendingActionsService().pendingFor(
      userId: user,
      rooms: [room],
      competitions: [competition],
      activities: [activity],
      reports: [report],
      votes: votes,
      now: now,
    );

    test('eligible voters see the vote; the author does not', () {
      expect(pending('c').single.kind, PendingActionKind.vote);
      expect(pending('b').single.reportId, 'rep');
      expect(pending('a'), isEmpty);
    });

    test('a vote already cast is no longer pending', () {
      final vote = ReportVote(
        id: 'v',
        reportId: 'rep',
        voterUserId: 'c',
        vote: VoteType.valid,
        createdAt: now,
      );
      expect(pending('c', votes: [vote]), isEmpty);
    });

    test('a room member outside the competition is invited to join', () {
      final actions = pending('late');
      expect(actions.single.kind, PendingActionKind.join);
      expect(actions.single.label, 'Participe de "Desafio"');
    });

    test('rooms the user is not in are ignored', () {
      expect(pending('stranger'), isEmpty);
    });
  });
}
