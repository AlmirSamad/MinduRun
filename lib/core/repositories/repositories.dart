import 'dart:typed_data';

import '../models/models.dart';

/// Repository contracts. In-memory implementations back demo mode and act as
/// the local cache of the Supabase-synced mode.

/// Generates a globally unique id for a new entity (e.g. `room-…`).
typedef IdFactory = String Function(String prefix);

abstract interface class UserRepository {
  List<User> listUsers();
  User? getUser(String id);
  void addUser(User user);
  void clear();
}

abstract interface class RoomRepository {
  List<Room> listRooms();
  List<Room> listRoomsForUser(String userId);
  Room? getRoom(String id);
  Room? findByInviteCode(String inviteCode);
  void createRoom(Room room);

  /// Creates a room with a local ID/code and includes its owner as a member.
  Room createLocalRoom({
    required String name,
    required String ownerUserId,
    required DateTime createdAt,
  });

  /// Normalizes the code. Returns null when no room matches.
  Room? joinRoomByCode(String inviteCode, String userId);

  /// Adds [userId] to the room members. Returns the updated room, or null if
  /// the room does not exist.
  Room? joinRoom(String roomId, String userId);
  List<String> getMemberIds(String roomId);
  void clear();
}

abstract interface class CompetitionRepository {
  List<Competition> listCompetitions();
  List<Competition> listRoomCompetitions(String roomId);
  Competition? getCompetition(String id);
  List<String> getParticipantIds(String competitionId);

  /// User-facing creation, with owner permission and a participant snapshot.
  Competition createLocalCompetition({
    required Room room,
    required String creatorUserId,
    required String name,
    required DateTime startsAt,
    required DateTime endsAt,
    required DateTime now,
  });

  /// Seed/data-layer insertion. User actions use createLocalCompetition.
  void createCompetition(Competition competition);
  void updateCompetition(Competition competition);
  void clear();
}

abstract interface class ActivityRepository {
  /// Notifications for every mutation; readers query the repository again.
  Stream<void> get changes;
  void dispose();
  List<Activity> listActivities();

  /// Activities of a competition, newest first.
  List<Activity> listCompetitionActivities(String competitionId);
  Activity? getActivity(String id);
  void createActivity(Activity activity);

  /// Stores a validated submission, generating an ID and PUBLISHED status.
  Activity createLocalActivity({
    required String competitionId,
    required String userId,
    required double distanceKm,
    required int durationSeconds,
    required int averagePaceSecondsPerKm,
    required EvidenceRef evidenceRef,
    required int score,
    required DateTime submittedAt,
  });
  Activity? updateModerationStatus(
    String activityId,
    ActivityModerationStatus status,
  );
  void clear();
}

abstract interface class ModerationRepository {
  Stream<void> get changes;
  void dispose();
  List<ActivityReport> listReports();
  void createReport(ActivityReport report);
  ActivityReport? getReport(String id);
  List<ActivityReport> listActivityReports(String activityId);

  /// Adds one immutable vote; duplicates and resolved reports are rejected.
  void addVote(ReportVote vote);
  List<ReportVote> listReportVotes(String reportId);
  ActivityReport? resolveReport(String reportId, ReportStatus status);
  void clear();
}

abstract interface class EvidenceRepository {
  /// Registers a bundled asset as evidence and returns its reference.
  EvidenceRef registerAsset(String assetPath);

  /// Stores user-selected bytes for this session and returns its reference.
  EvidenceRef storeBytes(Uint8List bytes);

  /// Returns bytes for a memory reference, or null.
  Uint8List? getBytes(EvidenceRef ref);

  bool exists(EvidenceRef ref);

  /// Clears in-memory evidence (bundled assets are re-registered by seed).
  void clear();
}
