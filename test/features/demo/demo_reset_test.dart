import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/app/bootstrap/providers.dart';
import 'package:mindurun/core/models/models.dart';
import 'package:mindurun/core/services/demo_seed_service.dart';
import 'package:mindurun/features/activities/activity_providers.dart';
import 'package:mindurun/features/competitions/competition_providers.dart';
import 'package:mindurun/features/demo/demo_controller.dart';
import 'package:mindurun/features/moderation/moderation_providers.dart';
import 'package:mindurun/features/ranking/ranking_providers.dart';
import 'package:mindurun/features/rooms/room_providers.dart';
import 'package:mindurun/features/session/session_providers.dart';

void main() {
  test('complete reset is repeatable and refreshes initialized providers', () {
    final now = DateTime(2026, 10, 22, 12);
    final container = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(() => now)],
    );
    addTearDown(container.dispose);
    container.read(demoSeedServiceProvider).reset(now);
    void select(String id) => container
        .read(sessionControllerProvider.notifier)
        .selectUser(container.read(userRepositoryProvider).getUser(id)!);
    container.listen(currentUserRoomsProvider, (_, _) {});
    container.listen(competitionsForRoomProvider(DemoIds.room), (_, _) {});
    container.listen(
      activitiesForCompetitionProvider(DemoIds.competition),
      (_, _) {},
    );
    container.listen(
      reportsForCompetitionProvider(DemoIds.competition),
      (_, _) {},
    );
    container.listen(
      rankingForCompetitionProvider(DemoIds.competition),
      (_, _) {},
    );
    String? firstRoomId;
    String? firstCompetitionId;
    for (var repeat = 0; repeat < 2; repeat++) {
      select(DemoIds.almir);
      final room = container
          .read(roomsControllerProvider.notifier)
          .createRoom('Sala temporária');
      firstRoomId ??= room.id;
      expect(room.id, firstRoomId);
      select(DemoIds.ana);
      container
          .read(roomsControllerProvider.notifier)
          .joinRoom(room.inviteCode);
      select(DemoIds.almir);
      final competition = container
          .read(competitionsControllerProvider.notifier)
          .createCompetition(
            roomId: room.id,
            name: 'Competição temporária',
            startsAt: now.subtract(const Duration(hours: 1)),
            endsAt: now.add(const Duration(days: 1)),
          );
      firstCompetitionId ??= competition.id;
      expect(competition.id, firstCompetitionId);
      final evidence = container
          .read(evidenceRepositoryProvider)
          .storeBytes(Uint8List.fromList([1, 2, 3]));
      final activity = container
          .read(activitiesControllerProvider.notifier)
          .submitActivity(
            competitionId: competition.id,
            distance: '3',
            duration: '18:00',
            pace: '06:00',
            evidence: evidence,
          );
      select(DemoIds.ana);
      final report = container
          .read(moderationControllerProvider.notifier)
          .reportActivity(activity.id, ReportReason.other);
      container
          .read(moderationControllerProvider.notifier)
          .vote(report.id, VoteType.invalid);
      expect(
        container
            .read(activityRepositoryProvider)
            .getActivity(activity.id)!
            .moderationStatus,
        ActivityModerationStatus.rejected,
      );
      container
          .read(moderationControllerProvider.notifier)
          .vote('report-1', VoteType.valid);
      container
          .read(userRepositoryProvider)
          .addUser(const User(id: 'extra', displayName: 'Extra'));
      container.read(roomRepositoryProvider).joinRoom(DemoIds.room, 'extra');

      container.read(demoControllerProvider.notifier).reset();
      expect(container.read(currentUserProvider), isNull);
      expect(container.read(currentUserRoomsProvider), isEmpty);
      expect(container.read(userRepositoryProvider).listUsers(), hasLength(5));
      expect(container.read(availableUsersProvider), hasLength(5));
      expect(
        container.read(roomRepositoryProvider).listRooms().single.id,
        DemoIds.room,
      );
      expect(
        container.read(roomRepositoryProvider).getRoom(DemoIds.room)!.memberIds,
        hasLength(5),
      );
      expect(
        container
            .read(competitionRepositoryProvider)
            .listCompetitions()
            .single
            .id,
        DemoIds.competition,
      );
      expect(
        container.read(activityRepositoryProvider).listActivities(),
        hasLength(5),
      );
      expect(
        container.read(activityRepositoryProvider).getActivity(activity.id),
        isNull,
      );
      expect(
        container.read(evidenceRepositoryProvider).getBytes(evidence),
        isNull,
      );
      expect(
        container.read(moderationRepositoryProvider).getReport(report.id),
        isNull,
      );
      expect(
        container.read(moderationRepositoryProvider).listReportVotes(report.id),
        isEmpty,
      );
      expect(
        container
            .read(moderationRepositoryProvider)
            .listReportVotes('report-1'),
        isEmpty,
      );
      expect(
        container.read(moderationRepositoryProvider).listReports().single.id,
        'report-1',
      );
      select(DemoIds.almir);
      expect(container.read(currentUserRoomsProvider).single.id, DemoIds.room);
      expect(
        container.read(competitionsForRoomProvider(DemoIds.room)).single.id,
        DemoIds.competition,
      );
      expect(
        container.read(activitiesForCompetitionProvider(DemoIds.competition)),
        hasLength(5),
      );
      expect(
        container
            .read(reportsForCompetitionProvider(DemoIds.competition))
            .single
            .id,
        'report-1',
      );
      final ranking = container.read(
        rankingForCompetitionProvider(DemoIds.competition),
      );
      expect(ranking.map((e) => e.score), [1000, 710, 700, 523, 450]);
      expect(
        ranking.singleWhere((e) => e.userId == DemoIds.carlos).hasUnderReview,
        isTrue,
      );
      expect(
        container
            .read(competitionStateServiceProvider)
            .effectiveStatus(
              container
                  .read(competitionRepositoryProvider)
                  .getCompetition(DemoIds.competition)!,
              now,
            ),
        CompetitionStatus.active,
      );
    }
  });
}
