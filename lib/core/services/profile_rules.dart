/// Participant display name rules (synced mode; matches the `profiles`
/// table check: 2 to 30 characters after trimming).
abstract final class ProfileRules {
  static const maxNameLength = 30;

  static String? validateName(String? name) {
    final length = (name ?? '').trim().runes.length;
    return length < 2 || length > maxNameLength
        ? 'Informe um nome de 2 a 30 caracteres.'
        : null;
  }
}
