import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/app/bootstrap/providers.dart';
import 'package:mindurun/core/models/models.dart';
import 'package:mindurun/core/services/demo_seed_service.dart';
import 'package:mindurun/features/activities/activity_providers.dart';
import 'package:mindurun/features/activities/evidence_picker.dart';
import 'package:mindurun/features/rooms/room_providers.dart';
import 'package:mindurun/features/competitions/competition_providers.dart';
import 'package:mindurun/features/session/session_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;
  late DateTime now;
  Uint8List? picked;
  setUp(() {
    now = DateTime(2026, 10, 22, 12);
    picked = null;
    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        evidencePickerProvider.overrideWithValue(() async => picked),
      ],
    );
    container.read(demoSeedServiceProvider).reset(now);
  });
  tearDown(() => container.dispose());
  void select(String id) => container
      .read(sessionControllerProvider.notifier)
      .selectUser(container.read(userRepositoryProvider).getUser(id)!);
  Activity submit({
    String competitionId = DemoIds.competition,
    String distance = '5,23',
    String duration = '31:45',
    String pace = '06:04',
    EvidenceRef? evidence = const EvidenceRef.asset(
      'assets/demo/evidence_1.jpg',
    ),
  }) => container
      .read(activitiesControllerProvider.notifier)
      .submitActivity(
        competitionId: competitionId,
        distance: distance,
        duration: duration,
        pace: pace,
        evidence: evidence,
      );

  test(
    'valid submission calculates score and updates shared feed across sessions',
    () {
      select(DemoIds.almir);
      container.listen(
        activitiesForCompetitionProvider(DemoIds.competition),
        (_, _) {},
      );
      final activity = submit();
      expect(activity.score, 523);
      expect(activity.distanceKm, 5.23);
      expect(activity.durationSeconds, 1905);
      expect(activity.averagePaceSecondsPerKm, 364);
      expect(activity.userId, DemoIds.almir);
      expect(activity.moderationStatus, ActivityModerationStatus.published);
      expect(activity.submittedAt, now);
      expect(
        container
            .read(activitiesForCompetitionProvider(DemoIds.competition))
            .first
            .id,
        activity.id,
      );
      expect(container.read(activityByIdProvider(activity.id)), same(activity));
      select(DemoIds.ana);
      expect(
        container
            .read(activitiesForCompetitionProvider(DemoIds.competition))
            .first
            .id,
        activity.id,
      );
    },
  );
  test(
    'missing session, missing evidence and inconsistent data never insert',
    () {
      expect(submit, throwsStateError);
      select(DemoIds.almir);
      expect(() => submit(evidence: null), throwsFormatException);
      expect(
        () => submit(
          evidence: const EvidenceRef(id: 'missing', kind: EvidenceKind.memory),
        ),
        throwsFormatException,
      );
      expect(
        () => submit(distance: '5', duration: '30:00', pace: '08:00'),
        throwsFormatException,
      );
      expect(
        container.read(activityRepositoryProvider).listActivities(),
        hasLength(5),
      );
    },
  );
  test(
    'scheduled, finished and cancelled competitions reject participants',
    () {
      select(DemoIds.almir);
      final original = container
          .read(competitionRepositoryProvider)
          .getCompetition(DemoIds.competition)!;
      now = original.startsAt.subtract(const Duration(seconds: 1));
      expect(submit, throwsStateError);
      now = original.endsAt;
      expect(submit, throwsStateError);
      now = DateTime(2026, 10, 22, 12);
      container
          .read(competitionRepositoryProvider)
          .updateCompetition(
            original.copyWith(status: CompetitionStatus.cancelled),
          );
      container.invalidate(competitionsControllerProvider);
      expect(submit, throwsStateError);
    },
  );
  test('late room member is not a snapshot participant', () {
    select(DemoIds.almir);
    final room = container
        .read(roomsControllerProvider.notifier)
        .createRoom('Sala nova');
    final competition = container
        .read(competitionsControllerProvider.notifier)
        .createCompetition(
          roomId: room.id,
          name: 'Desafio ativo',
          startsAt: now.subtract(const Duration(days: 1)),
          endsAt: now.add(const Duration(days: 1)),
        );
    select(DemoIds.ana);
    container.read(roomsControllerProvider.notifier).joinRoom(room.inviteCode);
    expect(() => submit(competitionId: competition.id), throwsStateError);
  });
  test('publish revalidates permission after a successful preview', () {
    select(DemoIds.almir);
    final controller = container.read(activitiesControllerProvider.notifier);
    controller.preview(
      competitionId: DemoIds.competition,
      distance: '5,23',
      duration: '31:45',
      pace: '06:04',
      evidence: const EvidenceRef.asset('assets/demo/evidence_1.jpg'),
    );
    now = now.add(const Duration(days: 7));
    expect(submit, throwsStateError);
    expect(
      container.read(activityRepositoryProvider).listActivities(),
      hasLength(5),
    );
  });
  test('cancelled or corrupt image selection is handled without creating activities', () async {
    final controller = container.read(activitiesControllerProvider.notifier);
    expect(await controller.selectEvidence(), isNull);
    picked = Uint8List.fromList([1, 2, 3]);
    await expectLater(controller.selectEvidence(), throwsFormatException);
    // A supported signature is not enough: the image decoder must reject
    // a truncated JPEG too, without registering evidence or an activity.
    picked = Uint8List.fromList([0xff, 0xd8, 0xff, 0]);
    await expectLater(controller.selectEvidence(), throwsFormatException);
    picked = Uint8List(maxEvidenceBytes + 1);
    await expectLater(controller.selectEvidence(), throwsFormatException);
    expect(
      container.read(activityRepositoryProvider).listActivities(),
      hasLength(5),
    );
  });
  test('selected image becomes memory evidence and can be published', () async {
    picked = (await rootBundle.load('assets/demo/evidence_1.jpg')).buffer
        .asUint8List();
    final evidence = await container
        .read(activitiesControllerProvider.notifier)
        .selectEvidence();
    expect(evidence!.kind, EvidenceKind.memory);
    expect(
      container.read(evidenceRepositoryProvider).getBytes(evidence),
      picked,
    );
    select(DemoIds.almir);
    expect(submit(evidence: evidence).evidenceRef, evidence);
  });
}
