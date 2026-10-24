import '../models/models.dart';

/// Shared validation for room forms and repository creation.
abstract final class RoomRules {
  /// Members may leave; the owner stays (the room would have no owner).
  static bool canLeave(Room room, String? userId) =>
      userId != null &&
      room.memberIds.contains(userId) &&
      room.ownerUserId != userId;

  /// The owner may remove any other member.
  static bool canRemove(Room room, String? actorId, String targetId) =>
      actorId != null &&
      room.ownerUserId == actorId &&
      targetId != room.ownerUserId &&
      room.memberIds.contains(targetId);

  /// Deep link that opens the installed Android app on the join flow.
  static String inviteLink(String inviteCode) =>
      'mindurun://open/join/${inviteCode.toUpperCase()}';

  /// Ready-to-send invitation (WhatsApp etc.). The code is the main path;
  /// the link only works where the app is installed and links are tappable.
  static String inviteMessage({
    required String roomName,
    required String inviteCode,
  }) =>
      'Entre na minha sala "$roomName" no MinduRun! '
      'Abra o app, toque em "Entrar com código" e use: $inviteCode\n'
      'Se o app já estiver instalado: ${inviteLink(inviteCode)}';

  static String? validateName(String? name) {
    final length = (name ?? '').trim().runes.length;
    return length < 3 || length > 40
        ? 'O nome deve ter de 3 a 40 caracteres.'
        : null;
  }
}
