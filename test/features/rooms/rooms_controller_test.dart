import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/app/bootstrap/providers.dart';
import 'package:mindurun/core/services/demo_seed_service.dart';
import 'package:mindurun/features/rooms/room_providers.dart';
import 'package:mindurun/features/session/session_providers.dart';

void main() {
  late ProviderContainer container;
  setUp(() {
    container = ProviderContainer();
    container.read(demoSeedServiceProvider).reset(DateTime.now());
  });
  tearDown(() => container.dispose());
  test('mutations require a session', () {
    final controller = container.read(roomsControllerProvider.notifier);
    expect(() => controller.createRoom('Nova sala'), throwsStateError);
    expect(() => controller.joinRoom('MINDU1'), throwsStateError);
    expect(container.read(currentUserRoomsProvider), isEmpty);
  });
  test('room state is shared, filtered by session and reactive', () {
    final session = container.read(sessionControllerProvider.notifier);
    final users = container.read(userRepositoryProvider);
    session.selectUser(users.getUser(DemoIds.almir)!);
    final changes = <int>[];
    container.listen(
      currentUserRoomsProvider,
      (_, next) => changes.add(next.length),
    );
    expect(container.read(currentUserRoomsProvider), hasLength(1));
    final controller = container.read(roomsControllerProvider.notifier);
    final room = controller.createRoom('Corrida de Domingo');
    expect(container.read(currentUserRoomsProvider), hasLength(2));
    expect(
      container.read(roomMembersProvider(room.id)).single.id,
      DemoIds.almir,
    );
    session.logout();
    expect(container.read(currentUserRoomsProvider), isEmpty);
    session.selectUser(users.getUser(DemoIds.ana)!);
    expect(container.read(currentUserRoomsProvider), hasLength(1));
    expect(container.read(roomDetailsProvider(room.id)), isNull);
    expect(controller.joinRoom('INVALID'), isNull);
    controller.joinRoom(room.inviteCode.toLowerCase());
    expect(container.read(currentUserRoomsProvider), hasLength(2));
    expect(container.read(roomMembersProvider(room.id)).map((u) => u.id), [
      DemoIds.almir,
      DemoIds.ana,
    ]);
    controller.joinRoom(room.inviteCode);
    expect(
      container.read(roomDetailsProvider(room.id))!.memberIds,
      hasLength(2),
    );
    expect(changes, contains(2));
  });
}
