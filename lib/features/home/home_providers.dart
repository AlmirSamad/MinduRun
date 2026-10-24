import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/bootstrap/providers.dart';
import '../../core/services/pending_actions_service.dart';
import '../activities/activity_providers.dart';
import '../competitions/competition_providers.dart';
import '../moderation/moderation_providers.dart';
import '../rooms/room_providers.dart';
import '../session/session_providers.dart';

/// Votes and joins waiting for the current user. Depends only on the root
/// controllers (no family providers) so the home page stays cheap and free
/// of dependency diamonds when it resumes behind other routes.
final pendingActionsProvider = Provider<List<PendingAction>>((ref) {
  final user = ref.watch(currentUserProvider);
  final rooms = ref.watch(roomsControllerProvider);
  final competitions = ref.watch(competitionsControllerProvider);
  final activities = ref.watch(activitiesControllerProvider);
  ref.watch(moderationControllerProvider);
  if (user == null) return const [];
  final moderation = ref.read(moderationRepositoryProvider);
  final reports = moderation.listReports();
  return const PendingActionsService().pendingFor(
    userId: user.id,
    rooms: rooms,
    competitions: competitions,
    activities: activities,
    reports: reports,
    votes: [for (final r in reports) ...moderation.listReportVotes(r.id)],
    now: ref.watch(clockProvider)(),
  );
});
