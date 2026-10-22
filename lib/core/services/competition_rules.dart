import '../models/models.dart';

/// Creation rules shared by application state, forms and memory storage.
abstract final class CompetitionRules {
  static bool canCreate(Room room, String? userId) =>
      userId != null && room.ownerUserId == userId;

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
