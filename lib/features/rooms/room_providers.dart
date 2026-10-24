import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/bootstrap/providers.dart';
import '../../core/models/models.dart';
import '../../core/services/room_rules.dart';
import '../session/session_providers.dart';

/// Repository snapshots notify all room readers after a successful mutation.
class RoomsController extends Notifier<List<Room>> {
  @override
  List<Room> build() {
    ref.watch(syncRevisionProvider);
    return ref.watch(roomRepositoryProvider).listRooms();
  }

  String? validateName(String? name) => RoomRules.validateName(name);

  Room createRoom(String name) {
    final user = ref.read(currentUserProvider);
    if (user == null) throw StateError('Selecione um usuário.');
    final error = validateName(name);
    if (error != null) throw ArgumentError(error);
    final repo = ref.read(roomRepositoryProvider);
    final room = repo.createLocalRoom(
      name: name,
      ownerUserId: user.id,
      createdAt: ref.read(clockProvider)(),
    );
    state = repo.listRooms();
    return room;
  }

  /// The current user leaves [roomId] (not allowed for the owner). Their
  /// competition participation and activities are kept.
  void leaveRoom(String roomId) {
    final user = ref.read(currentUserProvider);
    final repo = ref.read(roomRepositoryProvider);
    final room = repo.getRoom(roomId);
    if (room == null || !RoomRules.canLeave(room, user?.id)) {
      throw StateError('O criador não pode sair da própria sala.');
    }
    repo.removeMember(roomId, user!.id);
    state = repo.listRooms();
  }

  /// The owner removes another member.
  void removeMember(String roomId, String userId) {
    final user = ref.read(currentUserProvider);
    final repo = ref.read(roomRepositoryProvider);
    final room = repo.getRoom(roomId);
    if (room == null || !RoomRules.canRemove(room, user?.id, userId)) {
      throw StateError('Somente o criador pode remover outros membros.');
    }
    repo.removeMember(roomId, userId);
    state = repo.listRooms();
  }

  Room? joinRoom(String code) {
    final user = ref.read(currentUserProvider);
    if (user == null) throw StateError('Selecione um usuário.');
    final repo = ref.read(roomRepositoryProvider);
    final room = repo.joinRoomByCode(code, user.id);
    if (room != null) state = repo.listRooms();
    return room;
  }
}

final roomsControllerProvider = NotifierProvider<RoomsController, List<Room>>(
  RoomsController.new,
);

final currentUserRoomsProvider = Provider<List<Room>>((ref) {
  final user = ref.watch(currentUserProvider);
  ref.watch(roomsControllerProvider);
  if (user == null) return const [];
  return ref.watch(roomRepositoryProvider).listRoomsForUser(user.id);
});

/// Details are only visible to members of this room.
final roomDetailsProvider = Provider.family<Room?, String>((ref, id) {
  final rooms = ref.watch(currentUserRoomsProvider);
  for (final room in rooms) {
    if (room.id == id) return room;
  }
  return null;
});

final roomMembersProvider = Provider.family<List<User>, String>((ref, id) {
  final room = ref.watch(roomDetailsProvider(id));
  if (room == null) return const [];
  final users = ref.watch(userRepositoryProvider);
  return List.unmodifiable(room.memberIds.map(users.getUser).whereType<User>());
});
