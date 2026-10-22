import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/core/models/models.dart';
import 'package:mindurun/core/repositories/in_memory_repositories.dart';
import 'package:mindurun/core/services/demo_seed_service.dart';
import 'package:mindurun/core/services/domain_services.dart';

void main() {
  late InMemoryUserRepository users;
  late InMemoryRoomRepository rooms;
  late InMemoryCompetitionRepository competitions;
  late InMemoryActivityRepository activities;
  late InMemoryModerationRepository moderation;
  late InMemoryEvidenceRepository evidence;
  late DemoSeedService seed;
  final now = DateTime(2030, 1, 15, 10);

  setUp(() {
    users = InMemoryUserRepository();
    rooms = InMemoryRoomRepository();
    competitions = InMemoryCompetitionRepository();
    activities = InMemoryActivityRepository();
    moderation = InMemoryModerationRepository();
    evidence = InMemoryEvidenceRepository();
    seed = DemoSeedService(
      users: users,
      rooms: rooms,
      competitions: competitions,
      activities: activities,
      moderation: moderation,
      evidence: evidence,
    )..reset(now);
  });

  test('loads users, room and active competition', () {
    expect(users.listUsers().length, greaterThanOrEqualTo(5));
    final room = rooms.getRoom(DemoIds.room)!;
    expect(room.name, 'Corrida do Mindu');
    expect(room.memberIds, containsAll(users.listUsers().map((u) => u.id)));

    final comp = competitions.getCompetition(DemoIds.competition)!;
    expect(comp.roomId, room.id);
    expect(
      const CompetitionStateService().effectiveStatus(comp, now),
      CompetitionStatus.active,
    );
  });

  test('activities exist with valid references and consistent values', () {
    final comp = competitions.getCompetition(DemoIds.competition)!;
    final list = activities.listCompetitionActivities(comp.id);
    expect(list, isNotEmpty);
    const pace = PaceValidationService();
    const scoring = ScoringService();
    for (final a in list) {
      expect(users.getUser(a.userId), isNotNull);
      expect(comp.participantIds, contains(a.userId));
      expect(evidence.exists(a.evidenceRef), isTrue);
      expect(a.evidenceRef.kind, EvidenceKind.asset);
      expect(a.score, scoring.calculateScore(a.distanceKm));
      expect(
        pace.validate(
          distanceKm: a.distanceKm,
          durationSeconds: a.durationSeconds,
          averagePaceSecondsPerKm: a.averagePaceSecondsPerKm,
        ),
        PaceValidationResult.valid,
      );
      expect(a.submittedAt.isAfter(comp.startsAt), isTrue);
    }
  });

  test('reported scenario references a valid activity', () {
    final reports = moderation.listActivityReports('activity-5');
    expect(reports, hasLength(1));
    final activity = activities.getActivity('activity-5')!;
    expect(activity.moderationStatus, ActivityModerationStatus.underReview);
    expect(reports.single.reporterUserId, isNot(activity.userId));
  });

  test('seed produces expected ranking', () {
    final comp = competitions.getCompetition(DemoIds.competition)!;
    final ranking = const RankingService().buildRanking(
      competitionId: comp.id,
      participantIds: comp.participantIds,
      activities: activities.listCompetitionActivities(comp.id),
    );
    expect(ranking.map((e) => e.userId), [
      DemoIds.joao,
      DemoIds.ana,
      DemoIds.carlos,
      DemoIds.almir,
      DemoIds.marina,
    ]);
  });

  test('reset restores the seed state', () {
    rooms.joinRoom(DemoIds.room, 'intruder');
    activities.updateModerationStatus(
      'activity-1',
      ActivityModerationStatus.rejected,
    );
    seed.reset(now);
    expect(rooms.getRoom(DemoIds.room)!.memberIds, isNot(contains('intruder')));
    expect(
      activities.getActivity('activity-1')!.moderationStatus,
      ActivityModerationStatus.published,
    );
  });
}
