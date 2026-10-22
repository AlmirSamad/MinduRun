import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/core/repositories/in_memory_repositories.dart';
import 'package:mindurun/core/models/models.dart';

void main() {
  late InMemoryRoomRepository repo;
  late Room room;
  setUp(() {
    repo = InMemoryRoomRepository();
    room = repo.createLocalRoom(
      name: '  Corrida de Domingo  ',
      ownerUserId: 'almir',
      createdAt: DateTime(2026),
    );
  });
  test('creates room with owner, membership, trimmed name and invite', () {
    expect(repo.getRoom(room.id), same(room));
    expect(room.name, 'Corrida de Domingo');
    expect(room.ownerUserId, 'almir');
    expect(room.memberIds, ['almir']);
    expect(room.inviteCode, isNotEmpty);
    expect(repo.getMemberIds(room.id), ['almir']);
  });
  test('lists only rooms for a member', () {
    expect(repo.listRoomsForUser('almir'), [room]);
    expect(repo.listRoomsForUser('ana'), isEmpty);
  });
  test('joins by trimmed lowercase code and preserves invite', () {
    final joined = repo.joinRoomByCode(
      ' ${room.inviteCode.toLowerCase()} ',
      'ana',
    )!;
    expect(joined.memberIds, ['almir', 'ana']);
    expect(joined.inviteCode, room.inviteCode);
    expect(repo.listRoomsForUser('ana'), [joined]);
  });
  test('invalid code returns null without mutation', () {
    expect(repo.joinRoomByCode('UNKNOWN', 'ana'), isNull);
    expect(repo.getMemberIds(room.id), ['almir']);
  });
  test('rejoining does not duplicate members', () {
    repo.joinRoomByCode(room.inviteCode, 'ana');
    repo.joinRoomByCode(room.inviteCode, 'ana');
    expect(repo.getMemberIds(room.id), ['almir', 'ana']);
  });
  test('local ids and codes do not collide with existing rooms', () {
    repo.createRoom(
      Room(
        id: 'room-local-0002',
        name: 'Seed room',
        ownerUserId: 'almir',
        inviteCode: 'MR0002',
        memberIds: ['almir'],
        createdAt: DateTime(2026),
      ),
    );
    final next = repo.createLocalRoom(
      name: 'Outra sala',
      ownerUserId: 'ana',
      createdAt: DateTime(2026),
    );
    expect(next.id, isNot(room.id));
    expect(next.inviteCode, isNot('MR0002'));
    expect(repo.listRooms(), hasLength(3));
  });
  test('invalid names do not create rooms', () {
    for (final name in ['', '  ', 'ab', 'x' * 41]) {
      expect(
        () => repo.createLocalRoom(
          name: name,
          ownerUserId: 'almir',
          createdAt: DateTime(2026),
        ),
        throwsArgumentError,
      );
    }
    expect(repo.listRooms(), hasLength(1));
  });
}
