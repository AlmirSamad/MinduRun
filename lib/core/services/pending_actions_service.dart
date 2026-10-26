import '../models/models.dart';
import 'competition_rules.dart';
import 'domain_services.dart';

enum PendingActionKind { vote, join }

/// Something the current user should do, linked to a competition.
class PendingAction {
  const PendingAction({
    required this.kind,
    required this.competitionId,
    required this.competitionName,
    this.reportId,
  });

  final PendingActionKind kind;
  final String competitionId;
  final String competitionName;
  final String? reportId;

  String get label => switch (kind) {
    PendingActionKind.vote => 'Vote numa denúncia em "$competitionName"',
    PendingActionKind.join => 'Participe de "$competitionName"',
  };
}

/// Lists open votes the user may cast and competitions they may still join
/// in their rooms, using the same rules as the screens (no notifications in
/// this MVP, so this is how people find out they are needed).
class PendingActionsService {
  const PendingActionsService({
    this.moderation = const ModerationService(),
    this.competitionState = const CompetitionStateService(),
  });

  final ModerationService moderation;
  final CompetitionStateService competitionState;

  List<PendingAction> pendingFor({
    required String userId,
    required List<Room> rooms,
    required List<Competition> competitions,
    required List<Activity> activities,
    required List<ActivityReport> reports,
    required List<ReportVote> votes,
    required DateTime now,
  }) {
    final myRooms = {
      for (final room in rooms)
        if (room.memberIds.contains(userId)) room.id: room,
    };
    final activitiesById = {for (final a in activities) a.id: a};
    final result = <PendingAction>[];
    for (final competition in competitions) {
      final room = myRooms[competition.roomId];
      if (room == null) continue;
      if (CompetitionRules.canJoin(
        competition: competition,
        room: room,
        userId: userId,
        effectiveStatus: competitionState.effectiveStatus(competition, now),
      )) {
        result.add(
          PendingAction(
            kind: PendingActionKind.join,
            competitionId: competition.id,
            competitionName: competition.name,
          ),
        );
      }
      for (final report in reports) {
        final activity = activitiesById[report.activityId];
        if (activity == null || activity.competitionId != competition.id) {
          continue;
        }
        if (moderation.canVote(
          activity: activity,
          report: report,
          voterUserId: userId,
          participantIds: competition.participantIds,
          votes: votes.where((v) => v.reportId == report.id).toList(),
        )) {
          result.add(
            PendingAction(
              kind: PendingActionKind.vote,
              competitionId: competition.id,
              competitionName: competition.name,
              reportId: report.id,
            ),
          );
        }
      }
    }
    // Votes first: an open report blocks the activity until the minimum.
    result.sort((a, b) => a.kind.index.compareTo(b.kind.index));
    return result;
  }
}
