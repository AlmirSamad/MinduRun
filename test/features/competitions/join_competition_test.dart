import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/app/bootstrap/providers.dart';
import 'package:mindurun/core/models/models.dart';
import 'package:mindurun/core/services/competition_rules.dart';
import 'package:mindurun/core/services/demo_seed_service.dart';
import 'package:mindurun/features/activities/activity_providers.dart';
import 'package:mindurun/features/competitions/competition_providers.dart';
import 'package:mindurun/features/rooms/room_providers.dart';
import 'package:mindurun/features/session/session_providers.dart';

void main() {
  final now = DateTime(2026, 10, 30, 12);

  Competition competition(List<String> participants) => Competition(
    id: 'c1',
    roomId: 'r1',
    name: 'Desafio',
    startsAt: now,
    endsAt: now.add(const Duration(days: 7)),
    status: CompetitionStatus.active,
    participantIds: participants,
  );

  final room = Room(
    id: 'r1',
    name: 'Sala',
    ownerUserId: 'u1',
    inviteCode: 'ABC234',
    memberIds: const ['u1', 'u2'],
    createdAt: now,
  );

  group('CompetitionRules.canJoin', () {
    bool canJoin(String? user, CompetitionStatus status, {Room? inRoom}) =>
        CompetitionRules.canJoin(
          competition: competition(const ['u1']),
          room: inRoom ?? room,
          userId: user,
          effectiveStatus: status,
        );

    test('room member outside the competition may join while open', () {
      expect(canJoin('u2', CompetitionStatus.active), isTrue);
      expect(canJoin('u2', CompetitionStatus.scheduled), isTrue);
    });

    test('closed competitions, participants and outsiders cannot join', () {
      expect(canJoin('u2', CompetitionStatus.finished), isFalse);
      expect(canJoin('u2', CompetitionStatus.cancelled), isFalse);
      expect(canJoin('u1', CompetitionStatus.active), isFalse);
      expect(canJoin('u3', CompetitionStatus.active), isFalse);
      expect(canJoin(null, CompetitionStatus.active), isFalse);
    });
  });

  test('a late room member joins and can then submit', () {
    final container = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(() => now)],
    );
    addTearDown(container.dispose);
    container.read(demoSeedServiceProvider).reset(now);
    final users = container.read(userRepositoryProvider);
    final session = container.read(sessionControllerProvider.notifier);

    session.selectUser(users.getUser(DemoIds.almir)!);
    final newRoom = container
        .read(roomsControllerProvider.notifier)
        .createRoom('Corrida Nova');
    final created = container
        .read(competitionsControllerProvider.notifier)
        .createCompetition(
          roomId: newRoom.id,
          name: 'Desafio Novo',
          startsAt: now.subtract(const Duration(hours: 1)),
          endsAt: now.add(const Duration(days: 7)),
        );
    expect(created.participantIds, [DemoIds.almir]);

    session.selectUser(users.getUser(DemoIds.ana)!);
    container
        .read(roomsControllerProvider.notifier)
        .joinRoom(newRoom.inviteCode);
    expect(container.read(canJoinCompetitionProvider(created.id)), isTrue);
    final service = container.read(activitySubmissionServiceProvider);
    expect(
      service.authorizationError(created, DemoIds.ana, now),
      'Você não é participante desta competição.',
    );

    final joined = container
        .read(competitionsControllerProvider.notifier)
        .joinCompetition(created.id);
    expect(joined.participantIds, [DemoIds.almir, DemoIds.ana]);
    expect(container.read(canJoinCompetitionProvider(created.id)), isFalse);
    expect(
      service.authorizationError(
        container.read(competitionByIdProvider(created.id)),
        DemoIds.ana,
        now,
      ),
      isNull,
    );
    expect(
      container.read(activitiesForCompetitionProvider(created.id)),
      isEmpty,
    );
    expect(
      () => container
          .read(competitionsControllerProvider.notifier)
          .joinCompetition(created.id),
      throwsStateError,
    );
  });
}
