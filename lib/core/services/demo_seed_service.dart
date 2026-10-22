import '../models/models.dart';
import '../repositories/repositories.dart';
import 'domain_services.dart';

/// Deterministic demo identifiers.
abstract final class DemoIds {
  static const almir = 'user-almir';
  static const ana = 'user-ana';
  static const carlos = 'user-carlos';
  static const joao = 'user-joao';
  static const marina = 'user-marina';

  static const room = 'room-corrida-do-mindu';
  static const competition = 'comp-desafio-semanal';
}

/// Bundled demo evidence screenshots.
abstract final class DemoAssets {
  static const evidence = [
    'assets/demo/evidence_1.jpg',
    'assets/demo/evidence_2.jpg',
    'assets/demo/evidence_3.jpg',
    'assets/demo/evidence_4.jpg',
    'assets/demo/evidence_5.jpg',
  ];
}

/// Loads (and resets) deterministic demo data into the repositories.
class DemoSeedService {
  const DemoSeedService({
    required this.users,
    required this.rooms,
    required this.competitions,
    required this.activities,
    required this.moderation,
    required this.evidence,
    this.scoring = const ScoringService(),
  });

  final UserRepository users;
  final RoomRepository rooms;
  final CompetitionRepository competitions;
  final ActivityRepository activities;
  final ModerationRepository moderation;
  final EvidenceRepository evidence;
  final ScoringService scoring;

  /// Clears every repository and loads the seed. Dates are relative to [now]
  /// so the competition stays active during the presentation.
  void reset(DateTime now) {
    users.clear();
    rooms.clear();
    competitions.clear();
    activities.clear();
    moderation.clear();
    evidence.clear();
    _seed(now);
  }

  void _seed(DateTime now) {
    const demoUsers = [
      User(id: DemoIds.almir, displayName: 'Almir'),
      User(id: DemoIds.ana, displayName: 'Ana'),
      User(id: DemoIds.carlos, displayName: 'Carlos'),
      User(id: DemoIds.joao, displayName: 'João'),
      User(id: DemoIds.marina, displayName: 'Marina'),
    ];
    demoUsers.forEach(users.addUser);
    final memberIds = List<String>.unmodifiable(demoUsers.map((u) => u.id));

    rooms.createRoom(
      Room(
        id: DemoIds.room,
        name: 'Corrida do Mindu',
        ownerUserId: DemoIds.almir,
        inviteCode: 'MINDU1',
        memberIds: memberIds,
        createdAt: now.subtract(const Duration(days: 7)),
      ),
    );

    competitions.createCompetition(
      Competition(
        id: DemoIds.competition,
        roomId: DemoIds.room,
        name: 'Desafio Semanal do Mindu',
        startsAt: now.subtract(const Duration(days: 1)),
        endsAt: now.add(const Duration(days: 6)),
        status: CompetitionStatus.active,
        participantIds: memberIds,
      ),
    );

    final refs = DemoAssets.evidence.map(evidence.registerAsset).toList();

    // (user, km, seconds, hoursAgo). Pace = round(seconds / km).
    final runs = <(String, double, int, int)>[
      (DemoIds.joao, 10.00, 3300, 20), // 5:30/km -> 1000 pts
      (DemoIds.ana, 7.10, 2556, 16), // 6:00/km -> 710 pts
      (DemoIds.almir, 5.23, 1830, 10), // 5:50/km -> 523 pts
      (DemoIds.marina, 4.50, 1395, 6), // 5:10/km -> 450 pts
      (DemoIds.carlos, 7.00, 2660, 2), // 6:20/km -> 700 pts (reported)
    ];
    for (var i = 0; i < runs.length; i++) {
      final (userId, km, seconds, hoursAgo) = runs[i];
      activities.createActivity(
        Activity(
          id: 'activity-${i + 1}',
          competitionId: DemoIds.competition,
          userId: userId,
          distanceKm: km,
          durationSeconds: seconds,
          averagePaceSecondsPerKm: (seconds / km).round(),
          evidenceRef: refs[i],
          score: scoring.calculateScore(km),
          moderationStatus: ActivityModerationStatus.published,
          submittedAt: now.subtract(Duration(hours: hoursAgo)),
        ),
      );
    }

    // Optional reported scenario: Marina reports Carlos' run.
    moderation.createReport(
      ActivityReport(
        id: 'report-1',
        activityId: 'activity-5',
        reporterUserId: DemoIds.marina,
        reason: ReportReason.distanceMismatch,
        details: 'A distância do print parece diferente.',
        status: ReportStatus.open,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
    );
    activities.updateModerationStatus(
      'activity-5',
      ActivityModerationStatus.underReview,
    );
  }
}
