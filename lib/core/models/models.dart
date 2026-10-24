import 'enums.dart';

export 'enums.dart';

/// Demo user (no real authentication).
class User {
  const User({
    required this.id,
    required this.displayName,
    this.avatarAssetPath,
  });

  final String id;
  final String displayName;
  final String? avatarAssetPath;
}

/// Private friend group.
class Room {
  const Room({
    required this.id,
    required this.name,
    required this.ownerUserId,
    required this.inviteCode,
    required this.memberIds,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String ownerUserId;
  final String inviteCode;
  final List<String> memberIds;
  final DateTime createdAt;

  Room copyWith({List<String>? memberIds, String? name}) => Room(
    id: id,
    name: name ?? this.name,
    ownerUserId: ownerUserId,
    inviteCode: inviteCode,
    memberIds: memberIds ?? this.memberIds,
    createdAt: createdAt,
  );
}

/// Time-bounded challenge inside a room.
///
/// [status] is the stored status; the effective status (which depends on the
/// current time) is computed by `CompetitionStateService`.
class Competition {
  const Competition({
    required this.id,
    required this.roomId,
    required this.name,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.participantIds,
  });

  final String id;
  final String roomId;
  final String name;
  final DateTime startsAt;
  final DateTime endsAt;
  final CompetitionStatus status;
  final List<String> participantIds;

  Competition copyWith({
    CompetitionStatus? status,
    List<String>? participantIds,
  }) => Competition(
    id: id,
    roomId: roomId,
    name: name,
    startsAt: startsAt,
    endsAt: endsAt,
    status: status ?? this.status,
    participantIds: participantIds ?? this.participantIds,
  );
}

/// Platform-neutral evidence reference. Never holds a `dart:io.File`.
///
/// For [EvidenceKind.asset], [id] is the Flutter asset path.
/// For [EvidenceKind.memory], [id] is a key in the evidence repository.
class EvidenceRef {
  const EvidenceRef({required this.id, required this.kind});

  const EvidenceRef.asset(String assetPath)
    : id = assetPath,
      kind = EvidenceKind.asset;

  final String id;
  final EvidenceKind kind;

  @override
  bool operator ==(Object other) =>
      other is EvidenceRef && other.id == id && other.kind == kind;

  @override
  int get hashCode => Object.hash(id, kind);
}

/// Submitted run.
class Activity {
  const Activity({
    required this.id,
    required this.competitionId,
    required this.userId,
    required this.distanceKm,
    required this.durationSeconds,
    required this.averagePaceSecondsPerKm,
    required this.evidenceRef,
    required this.score,
    required this.moderationStatus,
    required this.submittedAt,
    this.evidenceHash,
  });

  final String id;
  final String competitionId;
  final String userId;
  final double distanceKm;
  final int durationSeconds;
  final int averagePaceSecondsPerKm;
  final EvidenceRef evidenceRef;
  final int score;
  final ActivityModerationStatus moderationStatus;
  final DateTime submittedAt;

  /// SHA-256 of the evidence bytes (null for bundled demo evidence).
  final String? evidenceHash;

  Activity copyWith({ActivityModerationStatus? moderationStatus}) => Activity(
    id: id,
    competitionId: competitionId,
    userId: userId,
    distanceKm: distanceKm,
    durationSeconds: durationSeconds,
    averagePaceSecondsPerKm: averagePaceSecondsPerKm,
    evidenceRef: evidenceRef,
    score: score,
    moderationStatus: moderationStatus ?? this.moderationStatus,
    submittedAt: submittedAt,
    evidenceHash: evidenceHash,
  );
}

/// Challenge against an activity.
class ActivityReport {
  const ActivityReport({
    required this.id,
    required this.activityId,
    required this.reporterUserId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.details,
  });

  final String id;
  final String activityId;
  final String reporterUserId;
  final ReportReason reason;
  final String? details;
  final ReportStatus status;
  final DateTime createdAt;

  ActivityReport copyWith({ReportStatus? status}) => ActivityReport(
    id: id,
    activityId: activityId,
    reporterUserId: reporterUserId,
    reason: reason,
    details: details,
    status: status ?? this.status,
    createdAt: createdAt,
  );
}

/// Validation decision on a report.
class ReportVote {
  const ReportVote({
    required this.id,
    required this.reportId,
    required this.voterUserId,
    required this.vote,
    required this.createdAt,
  });

  final String id;
  final String reportId;
  final String voterUserId;
  final VoteType vote;
  final DateTime createdAt;
}
