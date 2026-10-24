import 'dart:typed_data';
import 'dart:async';

import '../models/models.dart';
import '../services/room_rules.dart';
import '../services/competition_rules.dart';
import '../services/domain_services.dart';
import 'repositories.dart';

/// In-memory implementations. Data lives only while the app runs.

class InMemoryUserRepository implements UserRepository {
  final Map<String, User> _users = {};

  @override
  List<User> listUsers() => List.unmodifiable(_users.values);

  @override
  User? getUser(String id) => _users[id];

  @override
  void addUser(User user) => _users[user.id] = user;

  @override
  void clear() => _users.clear();
}

class InMemoryRoomRepository implements RoomRepository {
  /// Without factories, ids and codes are sequential (deterministic demo).
  InMemoryRoomRepository({this.newId, this.newInviteCode});

  final IdFactory? newId;
  final String Function()? newInviteCode;
  final Map<String, Room> _rooms = {};
  int _nextId = 1;

  @override
  Room createLocalRoom({
    required String name,
    required String ownerUserId,
    required DateTime createdAt,
  }) {
    final normalized = name.trim();
    final error = RoomRules.validateName(normalized);
    if (error != null) throw ArgumentError(error);
    String id;
    String code;
    do {
      final number = (_nextId++)
          .toRadixString(36)
          .toUpperCase()
          .padLeft(4, '0');
      id = newId?.call('room') ?? 'room-local-$number';
      code = newInviteCode?.call() ?? 'MR$number';
    } while (_rooms.containsKey(id) || findByInviteCode(code) != null);
    final room = Room(
      id: id,
      name: normalized,
      ownerUserId: ownerUserId,
      inviteCode: code,
      memberIds: List.unmodifiable([ownerUserId]),
      createdAt: createdAt,
    );
    createRoom(room);
    return room;
  }

  @override
  Room? joinRoomByCode(String inviteCode, String userId) {
    final room = findByInviteCode(inviteCode);
    return room == null ? null : joinRoom(room.id, userId);
  }

  @override
  List<Room> listRooms() => List.unmodifiable(_rooms.values);

  @override
  List<Room> listRoomsForUser(String userId) => List.unmodifiable(
    _rooms.values.where((r) => r.memberIds.contains(userId)),
  );

  @override
  Room? getRoom(String id) => _rooms[id];

  @override
  Room? findByInviteCode(String inviteCode) {
    final code = inviteCode.trim().toUpperCase();
    for (final room in _rooms.values) {
      if (room.inviteCode.toUpperCase() == code) return room;
    }
    return null;
  }

  @override
  void createRoom(Room room) => _rooms[room.id] = room;

  @override
  Room? joinRoom(String roomId, String userId) {
    final room = _rooms[roomId];
    if (room == null) return null;
    if (room.memberIds.contains(userId)) return room;
    final updated = room.copyWith(
      memberIds: List.unmodifiable([...room.memberIds, userId]),
    );
    _rooms[roomId] = updated;
    return updated;
  }

  @override
  List<String> getMemberIds(String roomId) => _rooms[roomId]?.memberIds ?? [];

  @override
  void clear() {
    _rooms.clear();
    _nextId = 1;
  }
}

class InMemoryCompetitionRepository implements CompetitionRepository {
  InMemoryCompetitionRepository({this.newId});

  final IdFactory? newId;
  final Map<String, Competition> _competitions = {};
  int _nextId = 1;

  @override
  List<Competition> listCompetitions() =>
      List.unmodifiable(_competitions.values);

  @override
  List<String> getParticipantIds(String competitionId) => List.unmodifiable(
    _competitions[competitionId]?.participantIds ?? const <String>[],
  );

  @override
  Competition createLocalCompetition({
    required Room room,
    required String creatorUserId,
    required String name,
    required DateTime startsAt,
    required DateTime endsAt,
    required DateTime now,
  }) {
    if (!CompetitionRules.canCreate(room, creatorUserId)) {
      throw StateError('Somente o proprietário pode criar competições.');
    }
    final error =
        CompetitionRules.validateName(name) ??
        CompetitionRules.validatePeriod(startsAt, endsAt);
    if (error != null) throw ArgumentError(error);
    String id;
    do {
      id = newId?.call('competition') ?? 'competition-local-${_nextId++}';
    } while (_competitions.containsKey(id));
    final competition = Competition(
      id: id,
      roomId: room.id,
      name: name.trim(),
      startsAt: startsAt,
      endsAt: endsAt,
      status: CompetitionStatus.scheduled,
      participantIds: List<String>.unmodifiable(room.memberIds),
    );
    final created = competition.copyWith(
      status: const CompetitionStateService().effectiveStatus(competition, now),
    );
    createCompetition(created);
    return created;
  }

  @override
  List<Competition> listRoomCompetitions(String roomId) =>
      List.unmodifiable(_competitions.values.where((c) => c.roomId == roomId));

  @override
  Competition? getCompetition(String id) => _competitions[id];

  @override
  Competition? joinCompetition(String competitionId, String userId) {
    final competition = _competitions[competitionId];
    if (competition == null) return null;
    if (competition.participantIds.contains(userId)) return competition;
    final updated = competition.copyWith(
      participantIds: List.unmodifiable([
        ...competition.participantIds,
        userId,
      ]),
    );
    _competitions[competitionId] = updated;
    return updated;
  }

  @override
  void createCompetition(Competition competition) =>
      _competitions[competition.id] = competition;

  @override
  void updateCompetition(Competition competition) =>
      _competitions[competition.id] = competition;

  @override
  void clear() {
    _competitions.clear();
    _nextId = 1;
  }
}

class InMemoryActivityRepository implements ActivityRepository {
  InMemoryActivityRepository({this.newId});

  final IdFactory? newId;
  final Map<String, Activity> _activities = {};
  final _changes = StreamController<void>.broadcast(sync: true);
  int _nextId = 1;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  void dispose() => unawaited(_changes.close());

  @override
  List<Activity> listActivities() => List.unmodifiable(_activities.values);

  @override
  Future<bool> whenSaved(String activityId) =>
      Future.value(_activities.containsKey(activityId));

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
    String id;
    do {
      id = newId?.call('activity') ?? 'activity-local-${_nextId++}';
    } while (_activities.containsKey(id));
    final activity = Activity(
      id: id,
      competitionId: competitionId,
      userId: userId,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      averagePaceSecondsPerKm: averagePaceSecondsPerKm,
      evidenceRef: evidenceRef,
      score: score,
      moderationStatus: ActivityModerationStatus.published,
      submittedAt: submittedAt,
    );
    createActivity(activity);
    return activity;
  }

  @override
  List<Activity> listCompetitionActivities(String competitionId) {
    final list =
        _activities.values
            .where((a) => a.competitionId == competitionId)
            .toList()
          ..sort((a, b) {
            final order = b.submittedAt.compareTo(a.submittedAt);
            return order == 0 ? a.id.compareTo(b.id) : order;
          });
    return List.unmodifiable(list);
  }

  @override
  Activity? getActivity(String id) => _activities[id];

  @override
  void createActivity(Activity activity) {
    _activities[activity.id] = activity;
    _changes.add(null);
  }

  @override
  Activity? updateModerationStatus(
    String activityId,
    ActivityModerationStatus status,
  ) {
    final activity = _activities[activityId];
    if (activity == null) return null;
    final updated = activity.copyWith(moderationStatus: status);
    _activities[activityId] = updated;
    _changes.add(null);
    return updated;
  }

  @override
  void clear() {
    _activities.clear();
    _nextId = 1;
    _changes.add(null);
  }
}

class InMemoryModerationRepository implements ModerationRepository {
  final Map<String, ActivityReport> _reports = {};
  final Map<String, ReportVote> _votes = {};
  final _changes = StreamController<void>.broadcast(sync: true);

  @override
  Stream<void> get changes => _changes.stream;
  @override
  void dispose() => unawaited(_changes.close());
  @override
  List<ActivityReport> listReports() => List.unmodifiable(_reports.values);

  @override
  void createReport(ActivityReport report) {
    if (_reports.containsKey(report.id) ||
        _reports.values.any(
          (r) =>
              r.activityId == report.activityId &&
              (r.status == ReportStatus.open ||
                  r.reporterUserId == report.reporterUserId),
        )) {
      throw StateError(
        'Esta atividade já possui denúncia aberta ou sua denúncia já foi registrada.',
      );
    }
    _reports[report.id] = report;
    _changes.add(null);
  }

  @override
  ActivityReport? getReport(String id) => _reports[id];

  @override
  List<ActivityReport> listActivityReports(String activityId) =>
      List.unmodifiable(
        _reports.values.where((r) => r.activityId == activityId),
      );

  @override
  void addVote(ReportVote vote) {
    if (_reports[vote.reportId]?.status != ReportStatus.open) {
      throw StateError('Esta denúncia não está aberta.');
    }
    if (_votes.containsKey(vote.id) ||
        _votes.values.any(
          (v) =>
              v.reportId == vote.reportId && v.voterUserId == vote.voterUserId,
        )) {
      throw StateError('Seu voto já foi registrado.');
    }
    _votes[vote.id] = vote;
    _changes.add(null);
  }

  @override
  List<ReportVote> listReportVotes(String reportId) =>
      List.unmodifiable(_votes.values.where((v) => v.reportId == reportId));

  @override
  ActivityReport? resolveReport(String reportId, ReportStatus status) {
    final report = _reports[reportId];
    if (report == null) return null;
    if (report.status != ReportStatus.open || status == ReportStatus.open) {
      throw StateError('Esta denúncia não pode ser resolvida novamente.');
    }
    final updated = report.copyWith(status: status);
    _reports[reportId] = updated;
    _changes.add(null);
    return updated;
  }

  /// Cache refresh from the remote store: stores without validation.
  void putReport(ActivityReport report) {
    _reports[report.id] = report;
    _changes.add(null);
  }

  /// Cache refresh from the remote store: stores without validation.
  void putVote(ReportVote vote) {
    _votes[vote.id] = vote;
    _changes.add(null);
  }

  @override
  void clear() {
    _reports.clear();
    _votes.clear();
    _changes.add(null);
  }
}

class InMemoryEvidenceRepository implements EvidenceRepository {
  final Set<String> _assets = {};
  final Map<String, Uint8List> _bytes = {};
  int _nextId = 1;

  @override
  EvidenceRef registerAsset(String assetPath) {
    _assets.add(assetPath);
    return EvidenceRef.asset(assetPath);
  }

  @override
  EvidenceRef storeBytes(Uint8List bytes) {
    final id = 'mem-evidence-${_nextId++}';
    _bytes[id] = Uint8List.fromList(bytes).asUnmodifiableView();
    return EvidenceRef(id: id, kind: EvidenceKind.memory);
  }

  @override
  Uint8List? getBytes(EvidenceRef ref) =>
      ref.kind == EvidenceKind.memory ? _bytes[ref.id] : null;

  @override
  bool exists(EvidenceRef ref) => switch (ref.kind) {
    EvidenceKind.asset => _assets.contains(ref.id),
    EvidenceKind.memory => _bytes.containsKey(ref.id),
    EvidenceKind.remote => false,
  };

  @override
  void clear() {
    _assets.clear();
    _bytes.clear();
    _nextId = 1;
  }
}
