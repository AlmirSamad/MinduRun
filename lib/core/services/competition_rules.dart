import '../models/models.dart';

/// Creation rules shared by application state, forms and memory storage.
abstract final class CompetitionRules {
  static bool canCreate(Room room, String? userId) =>
      userId != null && room.ownerUserId == userId;

  /// A room member who is not yet a participant may join while the
  /// competition is still [CompetitionStatus.scheduled] or active.
  static bool canJoin({
    required Competition competition,
    required Room room,
    required String? userId,
    required CompetitionStatus effectiveStatus,
  }) =>
      userId != null &&
      room.id == competition.roomId &&
      room.memberIds.contains(userId) &&
      !competition.participantIds.contains(userId) &&
      (effectiveStatus == CompetitionStatus.scheduled ||
          effectiveStatus == CompetitionStatus.active);

  static String? validateName(String? name) {
    final length = (name ?? '').trim().runes.length;
    return length < 3 || length > 50
        ? 'O nome deve ter de 3 a 50 caracteres.'
        : null;
  }

  static String? validatePeriod(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'Informe início e término.';
    return end.isAfter(start)
        ? null
        : 'O término deve ser posterior ao início.';
  }
}
