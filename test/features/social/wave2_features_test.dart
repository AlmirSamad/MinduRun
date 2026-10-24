import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/app/app.dart';
import 'package:mindurun/app/bootstrap/providers.dart';
import 'package:mindurun/app/router/app_router.dart';
import 'package:mindurun/core/models/models.dart';
import 'package:mindurun/core/services/activity_submission_service.dart';
import 'package:mindurun/core/services/demo_seed_service.dart';
import 'package:mindurun/core/services/profile_stats.dart';
import 'package:mindurun/core/services/room_rules.dart';
import 'package:mindurun/core/services/social_rules.dart';
import 'package:mindurun/features/activities/activity_providers.dart';
import 'package:mindurun/features/moderation/moderation_providers.dart';
import 'package:mindurun/features/rooms/room_providers.dart';
import 'package:mindurun/features/session/presentation/profile_page.dart';
import 'package:mindurun/features/session/session_providers.dart';
import 'package:mindurun/features/social/social_providers.dart';

void main() {
  final now = DateTime(2026, 10, 30, 12);
  final competition = Competition(
    id: 'c1',
    roomId: 'r1',
    name: 'Desafio',
    startsAt: now.subtract(const Duration(days: 1)),
    endsAt: now.add(const Duration(days: 6)),
    status: CompetitionStatus.active,
    participantIds: const ['a', 'b'],
  );
  Activity activity({
    String user = 'a',
    ActivityModerationStatus status = ActivityModerationStatus.published,
    double km = 5,
  }) => Activity(
    id: 'act-$user-$km',
    competitionId: 'c1',
    userId: user,
    distanceKm: km,
    durationSeconds: 1800,
    averagePaceSecondsPerKm: 360,
    evidenceRef: const EvidenceRef.asset('x'),
    score: (km * 100).round(),
    moderationStatus: status,
    submittedAt: now,
  );

  group('domain rules', () {
    const service = ActivitySubmissionService();
    test('delete: own, published, unreported, while active', () {
      bool can({
        Activity? a,
        String user = 'a',
        List<ActivityReport> reports = const [],
        DateTime? at,
      }) => service.canDelete(
        activity: a ?? activity(),
        userId: user,
        competition: competition,
        reports: reports,
        now: at ?? now,
      );
      expect(can(), isTrue);
      expect(can(user: 'b'), isFalse);
      expect(
        can(a: activity(status: ActivityModerationStatus.underReview)),
        isFalse,
      );
      expect(can(at: now.add(const Duration(days: 7))), isFalse);
      final dismissed = ActivityReport(
        id: 'r',
        activityId: activity().id,
        reporterUserId: 'b',
        reason: ReportReason.other,
        status: ReportStatus.dismissed,
        createdAt: now,
      );
      expect(can(reports: [dismissed]), isFalse);
    });

    test('rooms: members leave, owner stays and removes others', () {
      final room = Room(
        id: 'r1',
        name: 'Sala',
        ownerUserId: 'a',
        inviteCode: 'ABC234',
        memberIds: const ['a', 'b'],
        createdAt: now,
      );
      expect(RoomRules.canLeave(room, 'b'), isTrue);
      expect(RoomRules.canLeave(room, 'a'), isFalse);
      expect(RoomRules.canRemove(room, 'a', 'b'), isTrue);
      expect(RoomRules.canRemove(room, 'b', 'a'), isFalse);
      expect(RoomRules.canRemove(room, 'a', 'a'), isFalse);
    });

    test('social: participants only, no self-like, 1–280 chars', () {
      expect(
        SocialRules.canLike(
          activity: activity(),
          userId: 'b',
          participantIds: const ['a', 'b'],
        ),
        isTrue,
      );
      expect(
        SocialRules.canLike(
          activity: activity(),
          userId: 'a',
          participantIds: const ['a', 'b'],
        ),
        isFalse,
      );
      expect(
        SocialRules.canComment(userId: 'z', participantIds: const ['a']),
        isFalse,
      );
      expect(SocialRules.validateComment('  '), isNotNull);
      expect(SocialRules.validateComment('Boa!'), isNull);
      expect(SocialRules.validateComment('x' * 281), isNotNull);
    });

    test('profile stats use the ranking rule (rejected = 0)', () {
      final stats = const ProfileStatsService().statsFor('a', [
        activity(km: 5),
        activity(km: 3, status: ActivityModerationStatus.rejected),
        activity(user: 'b', km: 10),
      ]);
      expect(stats.activities, hasLength(2));
      expect(stats.points, 500);
      expect(stats.acceptedKm, 5);
      expect(stats.rejectedCount, 1);
    });
  });

  group('controllers (demo mode)', () {
    late ProviderContainer container;
    late DateTime clock;
    setUp(() {
      clock = DateTime.now();
      container = ProviderContainer(
        overrides: [clockProvider.overrideWithValue(() => clock)],
      );
      container.read(demoSeedServiceProvider).reset(clock);
    });
    tearDown(() => container.dispose());
    void select(String id) => container
        .read(sessionControllerProvider.notifier)
        .selectUser(container.read(userRepositoryProvider).getUser(id)!);

    test('author deletes a fresh activity; others cannot', () {
      select(DemoIds.almir);
      final activity = container
          .read(activitiesControllerProvider.notifier)
          .submitActivity(
            competitionId: DemoIds.competition,
            distance: '3',
            duration: '18:00',
            pace: '06:00',
            evidence: const EvidenceRef.asset('assets/demo/evidence_2.jpg'),
          );
      expect(container.read(canDeleteActivityProvider(activity.id)), isTrue);
      select(DemoIds.ana);
      expect(container.read(canDeleteActivityProvider(activity.id)), isFalse);
      expect(
        () => container
            .read(activitiesControllerProvider.notifier)
            .deleteActivity(activity.id),
        throwsStateError,
      );
      select(DemoIds.almir);
      container
          .read(activitiesControllerProvider.notifier)
          .deleteActivity(activity.id);
      expect(
        container.read(activityRepositoryProvider).getActivity(activity.id),
        isNull,
      );
    });

    test('member leaves, owner removes, owner cannot leave', () {
      select(DemoIds.ana);
      final rooms = container.read(roomsControllerProvider.notifier);
      rooms.leaveRoom(DemoIds.room);
      expect(container.read(currentUserRoomsProvider), isEmpty);
      select(DemoIds.almir);
      expect(() => rooms.leaveRoom(DemoIds.room), throwsStateError);
      rooms.removeMember(DemoIds.room, DemoIds.joao);
      expect(
        container.read(roomRepositoryProvider).getMemberIds(DemoIds.room),
        isNot(contains(DemoIds.joao)),
      );
      // Competition participation is kept (ranking unchanged).
      expect(
        container
            .read(competitionRepositoryProvider)
            .getParticipantIds(DemoIds.competition),
        contains(DemoIds.joao),
      );
    });

    test('likes toggle and comments are validated', () {
      final target = container
          .read(activityRepositoryProvider)
          .listCompetitionActivities(DemoIds.competition)
          .firstWhere((a) => a.userId == DemoIds.joao);
      select(DemoIds.ana);
      final social = container.read(socialControllerProvider.notifier);
      social.toggleLike(target.id);
      expect(container.read(likesForActivityProvider(target.id)), hasLength(1));
      social.toggleLike(target.id);
      expect(container.read(likesForActivityProvider(target.id)), isEmpty);
      expect(() => social.addComment(target.id, '   '), throwsFormatException);
      social.addComment(target.id, '  Mandou bem!  ');
      expect(
        container.read(commentsForActivityProvider(target.id)).single.text,
        'Mandou bem!',
      );
      select(DemoIds.joao);
      expect(() => social.toggleLike(target.id), throwsStateError);
    });
  });

  testWidgets('profile page lists the user totals', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(demoSeedServiceProvider).reset(DateTime.now());
    container
        .read(sessionControllerProvider.notifier)
        .selectUser(
          container.read(userRepositoryProvider).getUser(DemoIds.joao)!,
        );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MinduRunApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-profile')));
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);
    expect(find.text('1000 pontos'), findsOneWidget);
    container.read(appRouterProvider).go(AppRoutes.home);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
