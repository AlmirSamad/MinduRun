import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/app/bootstrap/providers.dart';
import 'package:mindurun/core/services/demo_seed_service.dart';
import 'package:mindurun/features/competitions/competition_providers.dart';
import 'package:mindurun/features/rooms/room_providers.dart';
import 'package:mindurun/features/session/session_providers.dart';

void main() {
  late ProviderContainer container;
  final now = DateTime(2026, 10, 22, 12);
  setUp(() {
    container = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(() => now)],
    );
    container.read(demoSeedServiceProvider).reset(now);
  });
  tearDown(() => container.dispose());
  void select(String id) => container
      .read(sessionControllerProvider.notifier)
      .selectUser(container.read(userRepositoryProvider).getUser(id)!);
  void create({String roomId = DemoIds.room}) => container
      .read(competitionsControllerProvider.notifier)
      .createCompetition(
        roomId: roomId,
        name: 'Novo desafio',
        startsAt: now,
        endsAt: now.add(const Duration(days: 1)),
      );

  test('requires session, known room and owner permission outside the UI', () {
    expect(create, throwsStateError);
    select(DemoIds.ana);
    expect(container.read(canCreateCompetitionProvider(DemoIds.room)), isFalse);
    expect(create, throwsStateError);
    select(DemoIds.almir);
    expect(() => create(roomId: 'missing'), throwsStateError);
    expect(container.read(canCreateCompetitionProvider(DemoIds.room)), isTrue);
    create();
    expect(
      container.read(competitionsForRoomProvider(DemoIds.room)),
      hasLength(2),
    );
  });
  test(
    'creation notifies readers and remains visible after switching users',
    () {
      select(DemoIds.almir);
      final changes = <int>[];
      container.listen(
        competitionsForRoomProvider(DemoIds.room),
        (_, next) => changes.add(next.length),
      );
      expect(
        container.read(competitionsForRoomProvider(DemoIds.room)),
        hasLength(1),
      );
      create();
      final list = container.read(competitionsForRoomProvider(DemoIds.room));
      expect(list, hasLength(2));
      expect(changes, contains(2));
      final competition = list.last;
      select(DemoIds.ana);
      expect(
        container.read(competitionByIdProvider(competition.id)),
        isNotNull,
      );
      expect(
        container.read(competitionParticipantsProvider(competition.id)),
        hasLength(5),
      );
      expect(
        container.read(canCreateCompetitionProvider(DemoIds.room)),
        isFalse,
      );
      container.read(sessionControllerProvider.notifier).logout();
      expect(
        container.read(competitionsForRoomProvider(DemoIds.room)),
        isEmpty,
      );
      expect(container.read(competitionByIdProvider(competition.id)), isNull);
    },
  );
  test(
    'late room members can view competitions but are not added to snapshot',
    () {
      select(DemoIds.almir);
      final room = container
          .read(roomsControllerProvider.notifier)
          .createRoom('Sala nova');
      create(roomId: room.id);
      final competition = container
          .read(competitionsForRoomProvider(room.id))
          .single;
      select(DemoIds.ana);
      expect(container.read(competitionByIdProvider(competition.id)), isNull);
      container
          .read(roomsControllerProvider.notifier)
          .joinRoom(room.inviteCode);
      expect(
        container.read(competitionByIdProvider(competition.id)),
        isNotNull,
      );
      expect(
        container
            .read(competitionParticipantsProvider(competition.id))
            .map((u) => u.id),
        [DemoIds.almir],
      );
    },
  );
}
