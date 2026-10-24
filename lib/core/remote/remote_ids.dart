import 'dart:math';

final _random = Random.secure();

/// Globally unique id, safe to generate on any phone without coordination.
String newRemoteId(String prefix) {
  final hex = List.generate(
    16,
    (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  return '$prefix-$hex';
}

/// Short invite code without ambiguous characters (0/O, 1/I/L).
String newRemoteInviteCode() {
  const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  return List.generate(
    6,
    (_) => alphabet[_random.nextInt(alphabet.length)],
  ).join();
}
