import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/bootstrap/providers.dart';
import '../../core/models/models.dart';
import '../../core/services/profile_stats.dart';
import '../../core/services/social_rules.dart';
import '../activities/activity_providers.dart';
import '../competitions/competition_providers.dart';
import '../session/session_providers.dart';

/// Revision only: likes and comments stay owned by the repository.
class SocialController extends Notifier<int> {
  int _nextId = 1;

  @override
  int build() {
    final subscription = ref
        .watch(socialRepositoryProvider)
        .changes
        .listen((_) => state++);
    ref.onDispose(subscription.cancel);
    return 0;
  }

  List<String> _participants(Activity activity) =>
      ref
          .read(competitionByIdProvider(activity.competitionId))
          ?.participantIds ??
      const [];

  void toggleLike(String activityId) {
    final activity = ref.read(activityByIdProvider(activityId));
    final user = ref.read(currentUserProvider);
    if (activity == null ||
        !SocialRules.canLike(
          activity: activity,
          userId: user?.id,
          participantIds: _participants(activity),
        )) {
      throw StateError('Só participantes curtem atividades de outras pessoas.');
    }
    final repo = ref.read(socialRepositoryProvider);
    final liked = repo.listLikes(activityId).any((l) => l.userId == user!.id);
    repo.setLike(
      ActivityLike(
        activityId: activityId,
        userId: user!.id,
        createdAt: ref.read(clockProvider)(),
      ),
      liked: !liked,
    );
  }

  ActivityComment addComment(String activityId, String text) {
    final activity = ref.read(activityByIdProvider(activityId));
    final user = ref.read(currentUserProvider);
    if (activity == null ||
        !SocialRules.canComment(
          userId: user?.id,
          participantIds: _participants(activity),
        )) {
      throw StateError('Só participantes da competição podem comentar.');
    }
    final error = SocialRules.validateComment(text);
    if (error != null) throw FormatException(error);
    final comment = ActivityComment(
      id:
          ref.read(newIdProvider)?.call('comment') ??
          'comment-local-${_nextId++}',
      activityId: activityId,
      userId: user!.id,
      text: text.trim(),
      createdAt: ref.read(clockProvider)(),
    );
    ref.read(socialRepositoryProvider).addComment(comment);
    return comment;
  }
}

final socialControllerProvider = NotifierProvider<SocialController, int>(
  SocialController.new,
);

final likesForActivityProvider = Provider.family<List<ActivityLike>, String>((
  ref,
  id,
) {
  ref.watch(socialControllerProvider);
  return ref.watch(socialRepositoryProvider).listLikes(id);
});

final commentsForActivityProvider =
    Provider.family<List<ActivityComment>, String>((ref, id) {
      ref.watch(socialControllerProvider);
      return ref.watch(socialRepositoryProvider).listComments(id);
    });

/// Whether the current user may like / comment on activity [id].
final socialPermissionsProvider =
    Provider.family<({bool like, bool comment}), String>((ref, id) {
      final activity = ref.watch(activityByIdProvider(id));
      final userId = ref.watch(currentUserProvider)?.id;
      if (activity == null) return (like: false, comment: false);
      final participants =
          ref
              .watch(competitionByIdProvider(activity.competitionId))
              ?.participantIds ??
          const <String>[];
      return (
        like: SocialRules.canLike(
          activity: activity,
          userId: userId,
          participantIds: participants,
        ),
        comment: SocialRules.canComment(
          userId: userId,
          participantIds: participants,
        ),
      );
    });

/// "Meu perfil": totals and history of the current user.
final profileStatsProvider = Provider<ProfileStats?>((ref) {
  final user = ref.watch(currentUserProvider);
  final activities = ref.watch(activitiesControllerProvider);
  if (user == null) return null;
  return ProfileStatsService(scoring: ref.watch(scoringServiceProvider))
      .statsFor(user.id, activities);
});
