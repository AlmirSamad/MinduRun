import 'dart:typed_data';

import '../models/models.dart';
import '../repositories/in_memory_repositories.dart';
import '../repositories/repositories.dart';
import '../services/evidence_hash.dart';
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
  Room? removeMember(String roomId, String userId) {
    final room = _cache.removeMember(roomId, userId);
    if (room != null) {
      _engine.enqueue(() => _engine.remote.removeMember(roomId, userId));
    }
    return room;
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

  @override
  Competition? joinCompetition(String competitionId, String userId) {
    final competition = _cache.joinCompetition(competitionId, userId);
    if (competition != null) {
      _engine.enqueue(() => _engine.remote.joinCompetition(competitionId));
    }
    return competition;
  }
}

class SyncedActivityRepository implements ActivityRepository {
  SyncedActivityRepository(this._engine, {this.evidence});
  final SyncEngine _engine;

  /// Uploads the activity's screenshot first when it is not on the server yet.
  final SyncedEvidenceRepository? evidence;
  final Map<String, Future<bool>> _saves = {};
  InMemoryActivityRepository get _cache => _engine.activities;

  @override
  Future<bool> whenSaved(String activityId) =>
      _saves[activityId] ??
      Future.value(_cache.getActivity(activityId) != null);

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
    String? evidenceHash,
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
      evidenceHash: evidenceHash,
    );
    _saves[activity.id] = _engine.enqueue(() async {
      if (evidenceRef.kind == EvidenceKind.remote) {
        await evidence?.ensureUploaded(evidenceRef.id);
      }
      await _engine.remote.insertActivity(activity);
    });
    return activity;
  }

  @override
  bool deleteActivity(String activityId) {
    final activity = _cache.getActivity(activityId);
    if (activity == null || !_cache.deleteActivity(activityId)) return false;
    _engine.enqueue(() => _engine.remote.deleteActivity(activity));
    return true;
  }

  /// Local only: the server derives moderation status in its report/vote
  /// functions, and the next refresh brings the authoritative value.
  @override
  Activity? updateModerationStatus(
    String activityId,
    ActivityModerationStatus status,
  ) => _cache.updateModerationStatus(activityId, status);
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

  /// The server function also puts the activity under review.
  @override
  void createReport(ActivityReport report) {
    _cache.createReport(report);
    _engine.enqueue(() => _engine.remote.createReport(report));
  }

  /// The server function also resolves the report when the minimum is met.
  @override
  void addVote(ReportVote vote) {
    _cache.addVote(vote);
    _engine.enqueue(() => _engine.remote.castVote(vote));
  }

  /// Local only (optimistic); the server resolves in `cast_vote`.
  @override
  ActivityReport? resolveReport(String reportId, ReportStatus status) =>
      _cache.resolveReport(reportId, status);
}

class SyncedSocialRepository implements SocialRepository {
  SyncedSocialRepository(this._engine);
  final SyncEngine _engine;
  InMemorySocialRepository get _cache => _engine.social;

  @override
  Stream<void> get changes => _cache.changes;
  @override
  void dispose() => _cache.dispose();
  @override
  List<ActivityLike> listLikes(String activityId) =>
      _cache.listLikes(activityId);
  @override
  List<ActivityComment> listComments(String activityId) =>
      _cache.listComments(activityId);
  @override
  void clear() => _cache.clear();

  @override
  void setLike(ActivityLike like, {required bool liked}) {
    _cache.setLike(like, liked: liked);
    _engine.enqueue(() => _engine.remote.setLike(like, liked: liked));
  }

  @override
  void addComment(ActivityComment comment) {
    _cache.addComment(comment);
    _engine.enqueue(() => _engine.remote.insertComment(comment));
  }
}

/// Uploads selected screenshots to the storage bucket under the user's
/// folder. The author's phone keeps the bytes to show them immediately.
class SyncedEvidenceRepository implements EvidenceRepository {
  SyncedEvidenceRepository(this._engine, {required this.userId});
  final SyncEngine _engine;
  final String userId;
  final Map<String, Uint8List> _bytes = {};
  final Set<String> _uploaded = {};

  @override
  EvidenceRef registerAsset(String assetPath) => EvidenceRef.asset(assetPath);

  /// Runs inside a queued job: uploads [path] unless already on the server.
  Future<void> ensureUploaded(String path) async {
    if (_uploaded.contains(path)) return;
    final bytes = _bytes[path];
    if (bytes == null) throw StateError('Evidência indisponível.');
    await _engine.remote.uploadEvidence(path, bytes);
    _uploaded.add(path);
  }

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
    // Start uploading while the user fills in the form; the activity job
    // retries it if this attempt fails.
    _engine.enqueue(() => ensureUploaded(path), silent: true);
    return EvidenceRef(id: path, kind: EvidenceKind.remote);
  }

  @override
  Uint8List? getBytes(EvidenceRef ref) =>
      ref.kind == EvidenceKind.remote ? _bytes[ref.id] : null;

  @override
  String? hashOf(EvidenceRef ref) {
    final bytes = getBytes(ref);
    return bytes == null ? null : evidenceHash(bytes);
  }

  @override
  bool exists(EvidenceRef ref) => switch (ref.kind) {
    EvidenceKind.asset => true,
    EvidenceKind.memory => false,
    EvidenceKind.remote => ref.id.isNotEmpty,
  };

  @override
  void clear() => _bytes.clear();
}
