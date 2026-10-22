import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/core/models/models.dart';
import 'package:mindurun/core/repositories/in_memory_repositories.dart';
import 'package:mindurun/core/services/domain_services.dart';

void main() {
  late InMemoryCompetitionRepository repo;
  late InMemoryRoomRepository rooms;
  late Room room;
  final now = DateTime(2026, 10, 22, 12);
  setUp(() {
    repo = InMemoryCompetitionRepository();
    rooms = InMemoryRoomRepository();
    room = Room(
      id: 'room',
      name: 'Sala',
      ownerUserId: 'almir',
      inviteCode: 'ROOM',
      memberIds: ['almir', 'ana', 'carlos'],
      createdAt: now,
    );
    rooms.createRoom(room);
  });
  Competition create({
    Room? source,
    String user = 'almir',
    String name = '  Desafio de Domingo  ',
    DateTime? start,
    DateTime? end,
  }) => repo.createLocalCompetition(
    room: source ?? room,
    creatorUserId: user,
    name: name,
    startsAt: start ?? now,
    endsAt: end ?? now.add(const Duration(days: 1)),
    now: now,
  );

  test(
    'owner creates with correct room, trimmed name, dates and participants',
    () {
      final competition = create();
      expect(repo.getCompetition(competition.id), same(competition));
      expect(competition.name, 'Desafio de Domingo');
      expect(competition.roomId, room.id);
      expect(competition.startsAt, now);
      expect(competition.endsAt, now.add(const Duration(days: 1)));
      expect(repo.getParticipantIds(competition.id), [
        'almir',
        'ana',
        'carlos',
      ]);
    },
  );
  test('list contains only competitions from the requested room', () {
    final first = create();
    final otherRoom = Room(
      id: 'other',
      name: 'Outra sala',
      ownerUserId: 'almir',
      inviteCode: 'OTHER',
      memberIds: ['almir'],
      createdAt: now,
    );
    final other = create(source: otherRoom);
    expect(repo.listRoomCompetitions(room.id), [first]);
    expect(repo.listRoomCompetitions(otherRoom.id), [other]);
    expect(repo.listRoomCompetitions('missing'), isEmpty);
    expect(repo.getParticipantIds('missing'), isEmpty);
  });
  test('member and outsider cannot create', () {
    for (final user in ['ana', 'outsider']) {
      expect(() => create(user: user), throwsStateError);
    }
    expect(repo.listCompetitions(), isEmpty);
  });
  test(
    'participant snapshot survives room changes and original list mutation',
    () {
      final competition = create();
      room.memberIds.add('marina');
      rooms.joinRoom(room.id, 'joao');
      expect(rooms.getMemberIds(room.id), containsAll(['marina', 'joao']));
      expect(competition.participantIds, ['almir', 'ana', 'carlos']);
      expect(
        () => competition.participantIds.add('intruder'),
        throwsUnsupportedError,
      );
    },
  );
  test('equal and reversed dates are rejected without inserting data', () {
    expect(() => create(end: now), throwsArgumentError);
    expect(
      () => create(end: now.subtract(const Duration(days: 1))),
      throwsArgumentError,
    );
    expect(repo.listCompetitions(), isEmpty);
  });
  test('invalid names are rejected; valid boundary lengths are accepted', () {
    for (final name in ['', '  ', 'ab', 'x' * 51]) {
      expect(() => create(name: name), throwsArgumentError);
    }
    expect(create(name: 'abc').name, 'abc');
    expect(create(name: 'x' * 50).name.length, 50);
  });
  test(
    'past periods are supported and stored status uses the existing service',
    () {
      final competition = create(
        start: now.subtract(const Duration(days: 10)),
        end: now.subtract(const Duration(days: 1)),
      );
      expect(competition.status, CompetitionStatus.finished);
      final scheduled = create(
        start: now.add(const Duration(days: 1)),
        end: now.add(const Duration(days: 5)),
      );
      expect(scheduled.status, CompetitionStatus.scheduled);
      expect(
        const CompetitionStateService().effectiveStatus(
          scheduled,
          scheduled.startsAt,
        ),
        CompetitionStatus.active,
      );
      expect(
        const CompetitionStateService().effectiveStatus(
          scheduled,
          scheduled.endsAt,
        ),
        CompetitionStatus.finished,
      );
    },
  );
  test('local IDs do not overwrite seeded or earlier competitions', () {
    repo.createCompetition(
      Competition(
        id: 'competition-local-1',
        roomId: room.id,
        name: 'Seed',
        startsAt: now,
        endsAt: now.add(const Duration(days: 1)),
        status: CompetitionStatus.active,
        participantIds: const ['almir'],
      ),
    );
    final first = create();
    final second = create();
    expect(first.id, isNot(second.id));
    expect(repo.listCompetitions(), hasLength(3));
    expect(repo.getCompetition('competition-local-1')!.name, 'Seed');
  });
}
