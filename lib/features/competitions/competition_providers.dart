import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/bootstrap/providers.dart';
import '../../core/models/models.dart';
import '../../core/services/competition_rules.dart';
import '../rooms/room_providers.dart';
import '../session/session_providers.dart';

class CompetitionsController extends Notifier<List<Competition>> {
  @override
  List<Competition> build() =>
      ref.watch(competitionRepositoryProvider).listCompetitions();

  Competition createCompetition({
    required String roomId,
    required String name,
    required DateTime startsAt,
    required DateTime endsAt,
  }) {
    final user = ref.read(currentUserProvider);
    if (user == null) throw StateError('Selecione um usuário.');
    final room = ref.read(roomRepositoryProvider).getRoom(roomId);
    if (room == null) throw StateError('Sala não encontrada.');
    if (!CompetitionRules.canCreate(room, user.id)) {
      throw StateError('Somente o proprietário pode criar competições.');
    }
    final repo = ref.read(competitionRepositoryProvider);
    final competition = repo.createLocalCompetition(
      room: room,
      creatorUserId: user.id,
      name: name,
      startsAt: startsAt,
      endsAt: endsAt,
      now: ref.read(clockProvider)(),
    );
    state = repo.listCompetitions();
    return competition;
  }
}

final competitionsControllerProvider =
    NotifierProvider<CompetitionsController, List<Competition>>(
      CompetitionsController.new,
    );

final canCreateCompetitionProvider = Provider.family<bool, String>((
  ref,
  roomId,
) {
  final room = ref.watch(roomDetailsProvider(roomId));
  return room != null &&
      CompetitionRules.canCreate(room, ref.watch(currentUserProvider)?.id);
});

/// Chronological order with a deterministic tie-break, independent of status.
final competitionsForRoomProvider = Provider.family<List<Competition>, String>((
  ref,
  roomId,
) {
  ref.watch(competitionsControllerProvider);
  if (ref.watch(roomDetailsProvider(roomId)) == null) return const [];
  final list =
      ref
          .watch(competitionRepositoryProvider)
          .listRoomCompetitions(roomId)
          .toList()
        ..sort((a, b) {
          final order = a.startsAt.compareTo(b.startsAt);
          return order == 0 ? a.id.compareTo(b.id) : order;
        });
  return List.unmodifiable(list);
});

final competitionByIdProvider = Provider.family<Competition?, String>((
  ref,
  id,
) {
  ref.watch(competitionsControllerProvider);
  final competition = ref
      .watch(competitionRepositoryProvider)
      .getCompetition(id);
  if (competition == null ||
      ref.watch(roomDetailsProvider(competition.roomId)) == null) {
    return null;
  }
  return competition;
});

final competitionParticipantsProvider = Provider.family<List<User>, String>((
  ref,
  id,
) {
  if (ref.watch(competitionByIdProvider(id)) == null) return const [];
  final ids = ref.watch(competitionRepositoryProvider).getParticipantIds(id);
  final users = ref.watch(userRepositoryProvider);
  return List.unmodifiable(ids.map(users.getUser).whereType<User>());
});

/// First currently-active competition in the current user's rooms.
final activeCompetitionProvider = Provider<Competition?>((ref) {
  ref.watch(competitionsControllerProvider);
  final repo = ref.watch(competitionRepositoryProvider);
  final state = ref.watch(competitionStateServiceProvider);
  final now = ref.watch(clockProvider)();
  for (final room in ref.watch(currentUserRoomsProvider)) {
    for (final c in repo.listRoomCompetitions(room.id)) {
      if (state.effectiveStatus(c, now) == CompetitionStatus.active) return c;
    }
  }
  return null;
});
