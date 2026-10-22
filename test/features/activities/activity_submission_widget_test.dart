import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/app/app.dart';
import 'package:mindurun/app/bootstrap/providers.dart';
import 'package:mindurun/app/router/app_router.dart';
import 'package:mindurun/core/models/models.dart';
import 'package:mindurun/core/services/demo_seed_service.dart';
import 'package:mindurun/features/activities/activity_providers.dart';
import 'package:mindurun/features/activities/evidence_picker.dart';
import 'package:mindurun/features/activities/presentation/evidence_image.dart';
import 'package:mindurun/features/competitions/competition_providers.dart';
import 'package:mindurun/features/session/session_providers.dart';

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> fillMetrics(
  WidgetTester tester, {
  String distance = '5,23',
  String duration = '31:45',
  String pace = '06:04',
}) async {
  for (final field in [
    (const Key('activity-distance'), distance),
    (const Key('activity-duration'), duration),
    (const Key('activity-pace'), pace),
  ]) {
    await tester.ensureVisible(find.byKey(field.$1));
    await tester.enterText(find.byKey(field.$1), field.$2);
  }
}

void main() {
  for (final size in const [Size(375, 800), Size(1400, 900)]) {
    testWidgets(
      'select image, validate, publish, view evidence and share feed at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final now = DateTime(2026, 10, 22, 12);
        final imageBytes = (await tester.runAsync(
          () => rootBundle.load('assets/demo/evidence_1.jpg'),
        ))!.buffer.asUint8List();
        final container = ProviderContainer(
          overrides: [
            clockProvider.overrideWithValue(() => now),
            evidencePickerProvider.overrideWithValue(() async => imageBytes),
          ],
        );
        addTearDown(container.dispose);
        container.read(demoSeedServiceProvider).reset(now);
        container
            .read(sessionControllerProvider.notifier)
            .selectUser(
              container.read(userRepositoryProvider).getUser(DemoIds.almir)!,
            );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MinduRunApp(),
          ),
        );
        await tester.pumpAndSettle();
        final router = container.read(appRouterProvider);
        router.go(AppRoutes.competition(DemoIds.competition));
        await tester.pumpAndSettle();
        await tapVisible(tester, find.text('Registrar atividade'));
        await tapVisible(tester, find.text('Validar e ver pontuação'));
        expect(find.text('Selecione uma imagem de evidência.'), findsOneWidget);
        expect(
          container.read(activityRepositoryProvider).listActivities(),
          hasLength(5),
        );
        await tester.ensureVisible(find.text('Selecionar screenshot'));
        // Await the async button action, including the engine's image decoder.
        // pumpAndSettle alone can finish before decoding schedules its next frame.
        final chooseImage = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Selecionar screenshot'),
        );
        await tester.runAsync(
          () => (chooseImage.onPressed! as Future<void> Function())(),
        );
        await tester.pumpAndSettle();
        expect(find.byType(EvidenceImage), findsOneWidget);
        await fillMetrics(
          tester,
          distance: '0',
          duration: '31:99',
          pace: '00:00',
        );
        await tapVisible(tester, find.text('Validar e ver pontuação'));
        expect(
          find.text('Informe uma distância maior que zero em km.'),
          findsOneWidget,
        );
        expect(
          find.text('Informe a duração em MM:SS ou HH:MM:SS, maior que zero.'),
          findsOneWidget,
        );
        expect(
          find.text('Informe o ritmo em MM:SS/km, maior que zero.'),
          findsOneWidget,
        );
        await fillMetrics(
          tester,
          distance: '5',
          duration: '30:00',
          pace: '08:00',
        );
        await tapVisible(tester, find.text('Validar e ver pontuação'));
        expect(
          find.text(
            'Os dados informados não são consistentes. Confira a distância, duração e ritmo médio.',
          ),
          findsOneWidget,
        );
        expect(
          container.read(activityRepositoryProvider).listActivities(),
          hasLength(5),
        );
        await fillMetrics(tester);
        await tapVisible(tester, find.text('Validar e ver pontuação'));
        expect(find.text('523 pontos'), findsOneWidget);
        final publish = find.text('Publicar atividade');
        if (publish.evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            publish,
            200,
            scrollable: find.byType(Scrollable).first,
          );
        }
        await tester.ensureVisible(publish);
        // Two clicks before a new frame must still create a single activity.
        await tester.tap(publish);
        await tester.tap(publish);
        await tester.pumpAndSettle();
        expect(
          container.read(activityRepositoryProvider).listActivities(),
          hasLength(6),
        );
        final activity = container
            .read(activitiesForCompetitionProvider(DemoIds.competition))
            .first;
        expect(activity.distanceKm, 5.23);
        expect(activity.evidenceRef.kind, EvidenceKind.memory);
        expect(activity.score, 523);
        final card = find.byKey(ValueKey('activity-${activity.id}'));
        await tester.scrollUntilVisible(
          card,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: card, matching: find.text('Almir')),
          findsOneWidget,
        );
        await tapVisible(
          tester,
          find.descendant(of: card, matching: find.text('Ver evidência')),
        );
        expect(find.byType(EvidenceImage), findsOneWidget);
        await tapVisible(tester, find.text('Fechar'));
        router.go(AppRoutes.home);
        await tester.pumpAndSettle();
        await tapVisible(tester, find.byTooltip('Trocar usuário'));
        await tapVisible(tester, find.text('Ana'));
        router.go(AppRoutes.competition(DemoIds.competition));
        await tester.pumpAndSettle();
        final sharedCard = find.byKey(ValueKey('activity-${activity.id}'));
        await tester.scrollUntilVisible(
          sharedCard,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(sharedCard);
        expect(
          find.descendant(of: sharedCard, matching: find.text('523 pontos')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('scheduled, finished and nonparticipant routes cannot submit', (
    tester,
  ) async {
    final now = DateTime(2026, 10, 22, 12);
    final container = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(() => now)],
    );
    addTearDown(container.dispose);
    container.read(demoSeedServiceProvider).reset(now);
    container
        .read(sessionControllerProvider.notifier)
        .selectUser(
          container.read(userRepositoryProvider).getUser(DemoIds.almir)!,
        );
    final original = container
        .read(competitionRepositoryProvider)
        .getCompetition(DemoIds.competition)!;
    final variants = [
      Competition(
        id: 'scheduled',
        roomId: original.roomId,
        name: 'Agendada',
        startsAt: now.add(const Duration(days: 1)),
        endsAt: now.add(const Duration(days: 2)),
        status: CompetitionStatus.active,
        participantIds: original.participantIds,
      ),
      Competition(
        id: 'finished',
        roomId: original.roomId,
        name: 'Finalizada',
        startsAt: now.subtract(const Duration(days: 2)),
        endsAt: now,
        status: CompetitionStatus.active,
        participantIds: original.participantIds,
      ),
      Competition(
        id: 'nonparticipant',
        roomId: original.roomId,
        name: 'Sem participação',
        startsAt: original.startsAt,
        endsAt: original.endsAt,
        status: CompetitionStatus.active,
        participantIds: const [DemoIds.ana],
      ),
    ];
    for (final competition in variants) {
      container
          .read(competitionRepositoryProvider)
          .createCompetition(competition);
    }
    container.invalidate(competitionsControllerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MinduRunApp(),
      ),
    );
    await tester.pumpAndSettle();
    final router = container.read(appRouterProvider);
    for (final competition in variants) {
      router.go(AppRoutes.competition(competition.id));
      await tester.pumpAndSettle();
      expect(find.text('Registrar atividade'), findsNothing);
      router.go(AppRoutes.newActivity(competition.id));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('activity-distance')), findsNothing);
      expect(find.text('Publicar atividade'), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });
}
