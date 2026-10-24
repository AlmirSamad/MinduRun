/// Manual input/formatting shared by the submission form, feed and tests.
abstract final class ActivityInput {
  static double? parseDistance(String text) {
    final value = text.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d+(?:\.\d+)?$').hasMatch(value)) return null;
    final distance = double.tryParse(value);
    if (distance == null ||
        !distance.isFinite ||
        distance <= 0 ||
        !(distance * 100).isFinite) {
      return null;
    }
    return distance;
  }

  /// MM:SS or HH:MM:SS. The minutes in MM:SS can exceed 59.
  static int? parseDuration(String text) {
    final value = text.trim();
    if (!RegExp(r'^\d+:\d{2}(?::\d{2})?$').hasMatch(value)) return null;
    final parts = value.split(':').map(int.tryParse).toList();
    if (parts.any((part) => part == null)) return null;
    final seconds = parts.last!;
    if (seconds > 59 || (parts.length == 3 && parts[1]! > 59)) return null;
    final total = parts.length == 3
        ? parts[0]! * 3600 + parts[1]! * 60 + seconds
        : parts[0]! * 60 + seconds;
    return total > 0 ? total : null;
  }

  static int? parsePace(String text) {
    if (!RegExp(r'^\d+:\d{2}$').hasMatch(text.trim())) return null;
    return parseDuration(text);
  }

  static String? validateDistance(String? text) =>
      parseDistance(text ?? '') == null
      ? 'Informe uma distância maior que zero em km.'
      : null;
  static String? validateDuration(String? text) =>
      parseDuration(text ?? '') == null
      ? 'Informe a duração em MM:SS ou HH:MM:SS, maior que zero.'
      : null;
  static String? validatePace(String? text) => parsePace(text ?? '') == null
      ? 'Informe o ritmo em MM:SS/km, maior que zero.'
      : null;

  static String formatDistance(double distance) =>
      '${distance.toStringAsFixed(2).replaceAll('.', ',')} km';
  static String _two(int value) => value.toString().padLeft(2, '0');
  static String formatDuration(int seconds) => seconds < 3600
      ? '${_two(seconds ~/ 60)}:${_two(seconds % 60)}'
      : '${_two(seconds ~/ 3600)}:${_two(seconds ~/ 60 % 60)}:${_two(seconds % 60)}';
  static String formatPace(int seconds) =>
      '${_two(seconds ~/ 60)}:${_two(seconds % 60)}/km';

  /// Pace (MM:SS, as typed in the form) implied by valid distance and
  /// duration texts, rounded to the second; null while either is invalid.
  static String? suggestPace(String distance, String duration) {
    final km = parseDistance(distance);
    final seconds = parseDuration(duration);
    if (km == null || seconds == null) return null;
    final pace = (seconds / km).round();
    if (pace <= 0) return null;
    return '${_two(pace ~/ 60)}:${_two(pace % 60)}';
  }
}
