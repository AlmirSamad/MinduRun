/// Shared validation for room forms and repository creation.
abstract final class RoomRules {
  static String? validateName(String? name) {
    final length = (name ?? '').trim().runes.length;
    return length < 3 || length > 40
        ? 'O nome deve ter de 3 a 40 caracteres.'
        : null;
  }
}
