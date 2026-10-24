import 'dart:typed_data';

import '../models/models.dart';

/// Every MinduRun row, used to rebuild the local cache.
class RemoteSnapshot {
  const RemoteSnapshot({
    this.users = const [],
    this.rooms = const [],
    this.competitions = const [],
    this.activities = const [],
    this.reports = const [],
    this.votes = const [],
  });

  final List<User> users;
  final List<Room> rooms;
  final List<Competition> competitions;
  final List<Activity> activities;
  final List<ActivityReport> reports;
  final List<ReportVote> votes;
}

/// Remote backend contract. The Supabase implementation lives in
/// `supabase_remote_store.dart`; tests use a fake.
abstract interface class RemoteStore {
  Future<RemoteSnapshot> fetchAll();
  Future<void> upsertProfile(User user);
  Future<void> insertRoom(Room room);
  Future<void> insertMember(String roomId, String userId);
  Future<void> insertCompetition(Competition competition);
  Future<void> insertActivity(Activity activity);
  Future<void> updateActivityStatus(
    String activityId,
    ActivityModerationStatus status,
  );
  Future<void> insertReport(ActivityReport report);
  Future<void> updateReportStatus(String reportId, ReportStatus status);
  Future<void> insertVote(ReportVote vote);
  Future<void> uploadEvidence(String path, Uint8List bytes);

  /// Public URL of an evidence object.
  String evidenceUrl(String path);

  /// Calls [onChange] whenever any MinduRun table changes. Returns a
  /// callback that stops watching.
  void Function() watch(void Function() onChange);
}

/// Row <-> model conversion. Enums are stored by `name`; dates in UTC.
abstract final class RemoteRows {
  static String _date(DateTime value) => value.toUtc().toIso8601String();
  static DateTime _parseDate(Object? value) =>
      DateTime.parse(value! as String).toLocal();

  static User user(Map<String, dynamic> row) =>
      User(id: row['id'] as String, displayName: row['display_name'] as String);

  static Map<String, dynamic> userRow(User user) => {
    'id': user.id,
    'display_name': user.displayName,
  };

  /// [memberRows] must be ordered by join time.
  static List<Room> rooms(
    List<Map<String, dynamic>> roomRows,
    List<Map<String, dynamic>> memberRows,
  ) {
    final members = <String, List<String>>{};
    for (final row in memberRows) {
      members
          .putIfAbsent(row['room_id'] as String, () => [])
          .add(row['user_id'] as String);
    }
    return [
      for (final row in roomRows)
        Room(
          id: row['id'] as String,
          name: row['name'] as String,
          ownerUserId: row['owner_id'] as String,
          inviteCode: row['invite_code'] as String,
          memberIds: List.unmodifiable(members[row['id']] ?? const []),
          createdAt: _parseDate(row['created_at']),
        ),
    ];
  }

  static Map<String, dynamic> roomRow(Room room) => {
    'id': room.id,
    'name': room.name,
    'owner_id': room.ownerUserId,
    'invite_code': room.inviteCode,
    'created_at': _date(room.createdAt),
  };

  static Competition competition(Map<String, dynamic> row) => Competition(
    id: row['id'] as String,
    roomId: row['room_id'] as String,
    name: row['name'] as String,
    startsAt: _parseDate(row['starts_at']),
    endsAt: _parseDate(row['ends_at']),
    status: CompetitionStatus.values.byName(row['status'] as String),
    participantIds: List.unmodifiable(
      (row['participant_ids'] as List).cast<String>(),
    ),
  );

  static Map<String, dynamic> competitionRow(Competition c) => {
    'id': c.id,
    'room_id': c.roomId,
    'name': c.name,
    'starts_at': _date(c.startsAt),
    'ends_at': _date(c.endsAt),
    'status': c.status.name,
    'participant_ids': c.participantIds,
  };

  static Activity activity(Map<String, dynamic> row) => Activity(
    id: row['id'] as String,
    competitionId: row['competition_id'] as String,
    userId: row['user_id'] as String,
    distanceKm: (row['distance_km'] as num).toDouble(),
    durationSeconds: row['duration_seconds'] as int,
    averagePaceSecondsPerKm: row['pace_seconds_per_km'] as int,
    evidenceRef: EvidenceRef(
      id: row['evidence_id'] as String,
      kind: EvidenceKind.values.byName(row['evidence_kind'] as String),
    ),
    score: row['score'] as int,
    moderationStatus: ActivityModerationStatus.values.byName(
      row['moderation_status'] as String,
    ),
    submittedAt: _parseDate(row['submitted_at']),
  );

  static Map<String, dynamic> activityRow(Activity a) => {
    'id': a.id,
    'competition_id': a.competitionId,
    'user_id': a.userId,
    'distance_km': a.distanceKm,
    'duration_seconds': a.durationSeconds,
    'pace_seconds_per_km': a.averagePaceSecondsPerKm,
    'evidence_kind': a.evidenceRef.kind.name,
    'evidence_id': a.evidenceRef.id,
    'score': a.score,
    'moderation_status': a.moderationStatus.name,
    'submitted_at': _date(a.submittedAt),
  };

  static ActivityReport report(Map<String, dynamic> row) => ActivityReport(
    id: row['id'] as String,
    activityId: row['activity_id'] as String,
    reporterUserId: row['reporter_id'] as String,
    reason: ReportReason.values.byName(row['reason'] as String),
    details: row['details'] as String?,
    status: ReportStatus.values.byName(row['status'] as String),
    createdAt: _parseDate(row['created_at']),
  );

  static Map<String, dynamic> reportRow(ActivityReport r) => {
    'id': r.id,
    'activity_id': r.activityId,
    'reporter_id': r.reporterUserId,
    'reason': r.reason.name,
    'details': r.details,
    'status': r.status.name,
    'created_at': _date(r.createdAt),
  };

  static ReportVote vote(Map<String, dynamic> row) => ReportVote(
    id: row['id'] as String,
    reportId: row['report_id'] as String,
    voterUserId: row['voter_id'] as String,
    vote: VoteType.values.byName(row['vote'] as String),
    createdAt: _parseDate(row['created_at']),
  );

  static Map<String, dynamic> voteRow(ReportVote v) => {
    'id': v.id,
    'report_id': v.reportId,
    'voter_id': v.voterUserId,
    'vote': v.vote.name,
    'created_at': _date(v.createdAt),
  };
}
