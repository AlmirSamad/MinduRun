import '../models/models.dart';

/// Likes and comments: only competition participants interact with an
/// activity; nobody likes their own activity; comments are 1–280 characters.
abstract final class SocialRules {
  static const maxCommentLength = 280;

  static bool canLike({
    required Activity activity,
    required String? userId,
    required List<String> participantIds,
  }) =>
      userId != null &&
      activity.userId != userId &&
      participantIds.contains(userId);

  static bool canComment({
    required String? userId,
    required List<String> participantIds,
  }) => userId != null && participantIds.contains(userId);

  static String? validateComment(String? text) {
    final length = (text ?? '').trim().runes.length;
    if (length == 0) return 'Escreva um comentário.';
    if (length > maxCommentLength) return 'Use até 280 caracteres.';
    return null;
  }
}
