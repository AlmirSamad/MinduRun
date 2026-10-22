import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/app/app.dart';
import 'package:mindurun/app/bootstrap/providers.dart';
import 'package:mindurun/app/router/app_router.dart';
import 'package:mindurun/core/models/models.dart';
import 'package:mindurun/core/services/demo_seed_service.dart';
import 'package:mindurun/features/activities/activity_providers.dart';
import 'package:mindurun/features/competitions/presentation/competition_details_page.dart';
import 'package:mindurun/features/session/session_providers.dart';

void main() {
  for (final size in const [Size(375, 800), Size(1400, 900)]) {
    testWidgets(
      'seed ranking reacts in place and survives user switch at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final now = DateTime(2026, 10, 22, 12);
        final container = ProviderContainer(
          overrides: [clockProvider.overrideWithValue(() => now)],
        );
        addTearDown(container.dispose);
        container.read(demoSeedServiceProvider).reset(now);
        void select(String id) => container
            .read(sessionControllerProvider.notifier)
            .selectUser(container.read(userRepositoryProvider).getUser(id)!);
        select(DemoIds.almir);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MinduRunApp(),
          ),
        );
        await tester.pumpAndSettle();
        container
            .read(appRouterProvider)
            .go(AppRoutes.competition(DemoIds.competition));
        await tester.pumpAndSettle();
        Finder row(String id) =>
            find.byKey(ValueKey('ranking-entry-${DemoIds.competition}-$id'));
        Future<void> show(Finder finder) async {
          await tester.ensureVisible(finder);
          await tester.pumpAndSettle();
        }

        void textIn(Finder finder, String text) => expect(
          find.descendant(of: finder, matching: find.text(text)),
          findsOneWidget,
        );
        await show(row(DemoIds.joao));
        textIn(row(DemoIds.joao), '1º');
        textIn(row(DemoIds.joao), '1000 pontos');
        textIn(row(DemoIds.carlos), '700 pontos');
        textIn(row(DemoIds.carlos), 'Em revisão');
        textIn(row(DemoIds.almir), 'Você');
        final page = tester.element(find.byType(CompetitionDetailsPage));
        container
            .read(activitiesControllerProvider.notifier)
            .submitActivity(
              competitionId: DemoIds.competition,
              distance: '5',
              duration: '30:00',
              pace: '06:00',
              evidence: const EvidenceRef.asset('assets/demo/evidence_1.jpg'),
            );
        await tester.pumpAndSettle();
        await show(row(DemoIds.almir));
        expect(tester.element(find.byType(CompetitionDetailsPage)), same(page));
        textIn(row(DemoIds.almir), '1º');
        textIn(row(DemoIds.almir), '1023 pontos');
        expect(
          tester.getTopLeft(row(DemoIds.almir)).dy,
          lessThan(tester.getTopLeft(row(DemoIds.joao)).dy),
        );
        select(DemoIds.ana);
        await tester.pumpAndSettle();
        await show(row(DemoIds.ana));
        textIn(row(DemoIds.ana), 'Você');
        textIn(row(DemoIds.almir), '1023 pontos');
        expect(
          find.descendant(of: row(DemoIds.almir), matching: find.text('Você')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'finished ranking includes zero scores and long names at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
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
        container
            .read(userRepositoryProvider)
            .addUser(
              const User(
                id: DemoIds.ana,
                displayName:
                    'Ana Maria de Albuquerque e Silva com nome comprido',
              ),
            );
        container
            .read(competitionRepositoryProvider)
            .createCompetition(
              Competition(
                id: 'finished',
                roomId: DemoIds.room,
                name: 'Competição encerrada',
                startsAt: now.subtract(const Duration(days: 3)),
                endsAt: now.subtract(const Duration(days: 1)),
                status: CompetitionStatus.active,
                participantIds: const [DemoIds.almir, DemoIds.ana],
              ),
            );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MinduRunApp(),
          ),
        );
        await tester.pumpAndSettle();
        container.read(appRouterProvider).go(AppRoutes.competition('finished'));
        await tester.pumpAndSettle();
        expect(find.text('FINALIZADA'), findsOneWidget);
        expect(find.text('Registrar atividade'), findsNothing);
        expect(find.text('Ranking'), findsOneWidget);
        expect(
          find.text('Ainda não há pontuação nesta competição.'),
          findsOneWidget,
        );
        expect(find.text('0 pontos'), findsNWidgets(2));
        expect(find.text('Você'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
