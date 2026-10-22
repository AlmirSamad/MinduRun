import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/app/bootstrap/providers.dart';
import 'package:mindurun/core/models/models.dart';
import 'package:mindurun/core/services/demo_seed_service.dart';
import 'package:mindurun/features/activities/activity_providers.dart';
import 'package:mindurun/features/ranking/ranking_providers.dart';
import 'package:mindurun/features/rooms/room_providers.dart';
import 'package:mindurun/features/session/session_providers.dart';

void main() {
  late ProviderContainer container;
  final now = DateTime(2026, 10, 22, 12);
  setUp(() {
    container = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(() => now)],
    );
    container.read(demoSeedServiceProvider).reset(now);
    container
        .read(sessionControllerProvider.notifier)
        .selectUser(
          container.read(userRepositoryProvider).getUser(DemoIds.almir)!,
        );
  });
  tearDown(() => container.dispose());
  Competition competition(
    String id, {
    String roomId = DemoIds.room,
    List<String> users = const [DemoIds.almir, DemoIds.ana],
    DateTime? start,
    DateTime? end,
  }) {
    final value = Competition(
      id: id,
      roomId: roomId,
      name: id,
      startsAt: start ?? now.subtract(const Duration(days: 1)),
      endsAt: end ?? now.add(const Duration(days: 1)),
      status: CompetitionStatus.active,
      participantIds: users,
    );
    container.read(competitionRepositoryProvider).createCompetition(value);
    return value;
  }

  Activity run(String id, String competitionId, String user, int score) {
    final activity = Activity(
      id: id,
      competitionId: competitionId,
      userId: user,
      distanceKm: score / 100,
      durationSeconds: 1800,
      averagePaceSecondsPerKm: 360,
      evidenceRef: const EvidenceRef.asset('assets/demo/evidence_1.jpg'),
      score: score,
      moderationStatus: ActivityModerationStatus.published,
      submittedAt: now,
    );
    container.read(activityRepositoryProvider).createActivity(activity);
    return activity;
  }

  test(
    'publication updates 500/700 to 800/700 immediately and agrees with feed',
    () {
      final comp = competition('reactive');
      run('almir-500', comp.id, DemoIds.almir, 500);
      run('ana-700', comp.id, DemoIds.ana, 700);
      final scores = <List<int>>[];
      container.listen(
        rankingForCompetitionProvider(comp.id),
        (_, entries) =>
            scores.add(entries.map((entry) => entry.score).toList()),
      );
      expect(
        container.read(rankingForCompetitionProvider(comp.id)).first.userId,
        DemoIds.ana,
      );
      container
          .read(activitiesControllerProvider.notifier)
          .submitActivity(
            competitionId: comp.id,
            distance: '3',
            duration: '18:00',
            pace: '06:00',
            evidence: const EvidenceRef.asset('assets/demo/evidence_1.jpg'),
          );
      final updated = container.read(rankingForCompetitionProvider(comp.id));
      expect(updated.map((entry) => entry.userId), [
        DemoIds.almir,
        DemoIds.ana,
      ]);
      expect(updated.map((entry) => entry.score), [800, 700]);
      final feed = container.read(activitiesForCompetitionProvider(comp.id));
      for (final entry in updated) {
        expect(
          entry.score,
          feed
              .where((activity) => activity.userId == entry.userId)
              .fold<int>(0, (sum, activity) => sum + activity.score),
        );
      }
      expect(scores, contains(orderedEquals([800, 700])));
      container
          .read(sessionControllerProvider.notifier)
          .selectUser(
            container.read(userRepositoryProvider).getUser(DemoIds.ana)!,
          );
      expect(
        container
            .read(rankingForCompetitionProvider(comp.id))
            .map((entry) => entry.score),
        [800, 700],
      );
    },
  );
  test(
    'raw repository changes, rejection and clear refresh ranking and feed',
    () {
      final comp = competition('repository-events');
      run('base', comp.id, DemoIds.almir, 500);
      container.listen(rankingForCompetitionProvider(comp.id), (_, _) {});
      expect(
        container.read(rankingForCompetitionProvider(comp.id)).first.score,
        500,
      );
      run('extra', comp.id, DemoIds.almir, 300);
      expect(
        container.read(rankingForCompetitionProvider(comp.id)).first.score,
        800,
      );
      final repo = container.read(activityRepositoryProvider);
      repo.updateModerationStatus(
        'extra',
        ActivityModerationStatus.underReview,
      );
      expect(
        container
            .read(rankingForCompetitionProvider(comp.id))
            .first
            .hasUnderReview,
        isTrue,
      );
      repo.updateModerationStatus('extra', ActivityModerationStatus.rejected);
      final entry = container
          .read(rankingForCompetitionProvider(comp.id))
          .first;
      expect(entry.score, 500);
      expect(entry.hasUnderReview, isFalse);
      expect(repo.getActivity('extra')!.score, 300);
      expect(
        container.read(activitiesForCompetitionProvider(comp.id)),
        hasLength(2),
      );
      repo.clear();
      expect(
        container
            .read(rankingForCompetitionProvider(comp.id))
            .map((entry) => entry.score),
        [0, 0],
      );
      expect(
        container.read(activitiesForCompetitionProvider(comp.id)),
        isEmpty,
      );
    },
  );
  test('isolates competitions in different rooms for the same user', () {
    final otherRoom = container
        .read(roomsControllerProvider.notifier)
        .createRoom('Outra sala');
    final a = competition('a');
    final b = competition('b', roomId: otherRoom.id, users: [DemoIds.almir]);
    run('a-run', a.id, DemoIds.almir, 1000);
    container.listen(rankingForCompetitionProvider(a.id), (_, _) {});
    expect(container.read(rankingForCompetitionProvider(b.id)).single.score, 0);
    run('b-run', b.id, DemoIds.almir, 9000);
    expect(
      container.read(rankingForCompetitionProvider(a.id)).first.score,
      1000,
    );
    expect(
      container.read(rankingForCompetitionProvider(b.id)).single.score,
      9000,
    );
  });
  test(
    'new room members never enter an existing competition snapshot ranking',
    () {
      final room = container
          .read(roomsControllerProvider.notifier)
          .createRoom('Snapshot');
      final comp = competition(
        'snapshot',
        roomId: room.id,
        users: [DemoIds.almir],
      );
      container.listen(rankingForCompetitionProvider(comp.id), (_, _) {});
      container.read(roomRepositoryProvider).joinRoom(room.id, DemoIds.carlos);
      run('nonparticipant-run', comp.id, DemoIds.carlos, 9999);
      final entries = container.read(rankingForCompetitionProvider(comp.id));
      expect(entries.map((entry) => entry.userId), [DemoIds.almir]);
      expect(entries.single.score, 0);
    },
  );
  test('ranking remains readable for scheduled and finished competitions', () {
    final scheduled = competition(
      'scheduled',
      start: now.add(const Duration(days: 1)),
      end: now.add(const Duration(days: 2)),
    );
    final finished = competition(
      'finished',
      start: now.subtract(const Duration(days: 2)),
      end: now.subtract(const Duration(days: 1)),
    );
    run('historical', finished.id, DemoIds.almir, 800);
    expect(
      container
          .read(rankingForCompetitionProvider(scheduled.id))
          .map((entry) => entry.score),
      [0, 0],
    );
    expect(
      container.read(rankingForCompetitionProvider(finished.id)).first.score,
      800,
    );
  });
}
