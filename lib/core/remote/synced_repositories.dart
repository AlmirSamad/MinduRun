import 'dart:typed_data';

import '../models/models.dart';
import '../repositories/in_memory_repositories.dart';
import '../repositories/repositories.dart';
import 'remote_ids.dart';
import 'sync_engine.dart';
import 'supabase_remote_store.dart';

/// Repositories for the Supabase-synced mode: reads and validation come from
/// the in-memory cache; successful writes are queued to the remote store.

class SyncedUserRepository implements UserRepository {
  SyncedUserRepository(this._engine);
  final SyncEngine _engine;
  InMemoryUserRepository get _cache => _engine.users;

  @override
  List<User> listUsers() => _cache.listUsers();
  @override
  User? getUser(String id) => _cache.getUser(id);
  @override
  void addUser(User user) {
    _cache.addUser(user);
    _engine.enqueue(() => _engine.remote.upsertProfile(user));
  }

  @override
  void clear() => _cache.clear();
}

class SyncedRoomRepository implements RoomRepository {
  SyncedRoomRepository(this._engine);
  final SyncEngine _engine;
  InMemoryRoomRepository get _cache => _engine.rooms;

  @override
  List<Room> listRooms() => _cache.listRooms();
  @override
  List<Room> listRoomsForUser(String userId) => _cache.listRoomsForUser(userId);
  @override
  Room? getRoom(String id) => _cache.getRoom(id);
  @override
  Room? findByInviteCode(String inviteCode) =>
      _cache.findByInviteCode(inviteCode);
  @override
  List<String> getMemberIds(String roomId) => _cache.getMemberIds(roomId);
  @override
  void createRoom(Room room) => _cache.createRoom(room);
  @override
  void clear() => _cache.clear();

  @override
  Room createLocalRoom({
    required String name,
    required String ownerUserId,
    required DateTime createdAt,
  }) {
    final room = _cache.createLocalRoom(
      name: name,
      ownerUserId: ownerUserId,
      createdAt: createdAt,
    );
    _engine.enqueue(() async {
      await _engine.remote.insertRoom(room);
      await _engine.remote.insertMember(room.id, ownerUserId);
    });
    return room;
  }

  @override
  Room? joinRoomByCode(String inviteCode, String userId) {
    final room = _cache.findByInviteCode(inviteCode);
    if (room == null) {
      // The room may have been created moments ago on another phone.
      _engine.refreshSoon();
      return null;
    }
    return joinRoom(room.id, userId);
  }

  @override
  Room? joinRoom(String roomId, String userId) {
    final alreadyMember = _cache.getMemberIds(roomId).contains(userId);
    final room = _cache.joinRoom(roomId, userId);
    if (room != null && !alreadyMember) {
      _engine.enqueue(() => _engine.remote.insertMember(roomId, userId));
    }
    return room;
  }
}

class SyncedCompetitionRepository implements CompetitionRepository {
  SyncedCompetitionRepository(this._engine);
  final SyncEngine _engine;
  InMemoryCompetitionRepository get _cache => _engine.competitions;

  @override
  List<Competition> listCompetitions() => _cache.listCompetitions();
  @override
  List<Competition> listRoomCompetitions(String roomId) =>
      _cache.listRoomCompetitions(roomId);
  @override
  Competition? getCompetition(String id) => _cache.getCompetition(id);
  @override
  List<String> getParticipantIds(String competitionId) =>
      _cache.getParticipantIds(competitionId);
  @override
  void createCompetition(Competition competition) =>
      _cache.createCompetition(competition);
  @override
  void updateCompetition(Competition competition) =>
      _cache.updateCompetition(competition);
  @override
  void clear() => _cache.clear();

  @override
  Competition createLocalCompetition({
    required Room room,
    required String creatorUserId,
    required String name,
    required DateTime startsAt,
    required DateTime endsAt,
    required DateTime now,
  }) {
    final competition = _cache.createLocalCompetition(
      room: room,
      creatorUserId: creatorUserId,
      name: name,
      startsAt: startsAt,
      endsAt: endsAt,
      now: now,
    );
    _engine.enqueue(() => _engine.remote.insertCompetition(competition));
    return competition;
  }
}

class SyncedActivityRepository implements ActivityRepository {
  SyncedActivityRepository(this._engine);
  final SyncEngine _engine;
  InMemoryActivityRepository get _cache => _engine.activities;

  @override
  Stream<void> get changes => _cache.changes;
  @override
  void dispose() => _cache.dispose();
  @override
  List<Activity> listActivities() => _cache.listActivities();
  @override
  List<Activity> listCompetitionActivities(String competitionId) =>
      _cache.listCompetitionActivities(competitionId);
  @override
  Activity? getActivity(String id) => _cache.getActivity(id);
  @override
  void createActivity(Activity activity) => _cache.createActivity(activity);
  @override
  void clear() => _cache.clear();

  @override
  Activity createLocalActivity({
    required String competitionId,
    required String userId,
    required double distanceKm,
    required int durationSeconds,
    required int averagePaceSecondsPerKm,
    required EvidenceRef evidenceRef,
    required int score,
    required DateTime submittedAt,
  }) {
    final activity = _cache.createLocalActivity(
      competitionId: competitionId,
      userId: userId,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      averagePaceSecondsPerKm: averagePaceSecondsPerKm,
      evidenceRef: evidenceRef,
      score: score,
      submittedAt: submittedAt,
    );
    _engine.enqueue(() => _engine.remote.insertActivity(activity));
    return activity;
  }

  @override
  Activity? updateModerationStatus(
    String activityId,
    ActivityModerationStatus status,
  ) {
    final activity = _cache.updateModerationStatus(activityId, status);
    if (activity != null) {
      _engine.enqueue(
        () => _engine.remote.updateActivityStatus(activityId, status),
      );
    }
    return activity;
  }
}

class SyncedModerationRepository implements ModerationRepository {
  SyncedModerationRepository(this._engine);
  final SyncEngine _engine;
  InMemoryModerationRepository get _cache => _engine.moderation;

  @override
  Stream<void> get changes => _cache.changes;
  @override
  void dispose() => _cache.dispose();
  @override
  List<ActivityReport> listReports() => _cache.listReports();
  @override
  ActivityReport? getReport(String id) => _cache.getReport(id);
  @override
  List<ActivityReport> listActivityReports(String activityId) =>
      _cache.listActivityReports(activityId);
  @override
  List<ReportVote> listReportVotes(String reportId) =>
      _cache.listReportVotes(reportId);
  @override
  void clear() => _cache.clear();

  @override
  void createReport(ActivityReport report) {
    _cache.createReport(report);
    _engine.enqueue(() => _engine.remote.insertReport(report));
  }

  @override
  void addVote(ReportVote vote) {
    _cache.addVote(vote);
    _engine.enqueue(() => _engine.remote.insertVote(vote));
  }

  @override
  ActivityReport? resolveReport(String reportId, ReportStatus status) {
    final report = _cache.resolveReport(reportId, status);
    if (report != null) {
      _engine.enqueue(
        () => _engine.remote.updateReportStatus(reportId, status),
      );
    }
    return report;
  }
}

/// Uploads selected screenshots to the storage bucket under the user's
/// folder. The author's phone keeps the bytes to show them immediately.
class SyncedEvidenceRepository implements EvidenceRepository {
  SyncedEvidenceRepository(this._engine, {required this.userId});
  final SyncEngine _engine;
  final String userId;
  final Map<String, Uint8List> _bytes = {};

  @override
  EvidenceRef registerAsset(String assetPath) => EvidenceRef.asset(assetPath);

  @override
  EvidenceRef storeBytes(Uint8List bytes) {
    final extension = switch (evidenceContentType(bytes)) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    final path = '$userId/${newRemoteId('evidence')}.$extension';
    final copy = Uint8List.fromList(bytes).asUnmodifiableView();
    _bytes[path] = copy;
    _engine.enqueue(() => _engine.remote.uploadEvidence(path, copy));
    return EvidenceRef(id: path, kind: EvidenceKind.remote);
  }

  @override
  Uint8List? getBytes(EvidenceRef ref) =>
      ref.kind == EvidenceKind.remote ? _bytes[ref.id] : null;

  @override
  bool exists(EvidenceRef ref) => switch (ref.kind) {
    EvidenceKind.asset => true,
    EvidenceKind.memory => false,
    EvidenceKind.remote => ref.id.isNotEmpty,
  };

  @override
  void clear() => _bytes.clear();
}
