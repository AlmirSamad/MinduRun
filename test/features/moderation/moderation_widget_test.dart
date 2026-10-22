import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/app/app.dart';
import 'package:mindurun/app/bootstrap/providers.dart';
import 'package:mindurun/app/router/app_router.dart';
import 'package:mindurun/core/services/demo_seed_service.dart';
import 'package:mindurun/features/activities/presentation/evidence_image.dart';
import 'package:mindurun/features/moderation/moderation_providers.dart';
import 'package:mindurun/features/ranking/ranking_providers.dart';
import 'package:mindurun/features/session/session_providers.dart';

void main() {
  for (final size in const [Size(375, 800), Size(1400, 900)]) {
    testWidgets(
      'report, evidence, author read-only, shared votes and rejected ranking at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final container = ProviderContainer(
          overrides: [
            clockProvider.overrideWithValue(() => DateTime(2026, 10, 22, 12)),
          ],
        );
        addTearDown(container.dispose);
        container
            .read(demoSeedServiceProvider)
            .reset(DateTime(2026, 10, 22, 12));
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
        final card = find.byKey(
          const ValueKey('activity-activity-2'),
        ); // Ana, 710 points.
        Finder inCard(String text) =>
            find.descendant(of: card, matching: find.text(text));
        Future<void> showCard() async {
          if (card.evaluate().isEmpty) {
            await tester.scrollUntilVisible(
              card,
              300,
              scrollable: find.byType(Scrollable).first,
            );
          }
          await tester.ensureVisible(card);
          await tester.pumpAndSettle();
        }

        Future<void> tap(Finder finder) async {
          await tester.ensureVisible(finder);
          await tester.tap(finder);
          await tester.pumpAndSettle();
        }

        int score() => container
            .read(rankingForCompetitionProvider(DemoIds.competition))
            .singleWhere((e) => e.userId == DemoIds.ana)
            .score;
        await showCard();
        await tap(inCard('Ver evidência'));
        expect(find.byType(EvidenceImage), findsOneWidget);
        await tap(find.text('Fechar'));
        final ownCard = find.byKey(const ValueKey('activity-activity-3'));
        expect(
          find.descendant(of: ownCard, matching: find.text('Reportar')),
          findsNothing,
        );
        await tap(inCard('Reportar'));
        expect(
          find.textContaining('A atividade entrará em revisão'),
          findsOneWidget,
        );
        await tester.enterText(
          find.byKey(const Key('report-details')),
          'A screenshot apresenta distância diferente. ' * 5,
        );
        await tap(find.text('Enviar denúncia'));
        expect(inCard('Em revisão'), findsOneWidget);
        expect(inCard('Reportar'), findsNothing);
        expect(score(), 710);
        final report = container
            .read(reportsForActivityProvider('activity-2'))
            .single;
        await tap(inCard('Ver votação'));
        expect(find.byType(EvidenceImage), findsOneWidget);
        await tap(find.text('A evidência é inconsistente'));
        expect(find.text('Seu voto foi registrado.'), findsOneWidget);
        expect(find.text('A evidência é inconsistente'), findsNothing);
        expect(find.text('1 de 3 votos necessários'), findsOneWidget);
        await tap(find.text('Fechar'));
        select(DemoIds.ana);
        await tester.pumpAndSettle();
        await showCard();
        await tap(inCard('Ver votação'));
        expect(
          find.text('O autor pode acompanhar a votação, mas não pode votar.'),
          findsOneWidget,
        );
        expect(find.text('A evidência é inconsistente'), findsNothing);
        expect(find.text('A atividade parece válida'), findsNothing);
        await tap(find.text('Fechar'));
        select(DemoIds.carlos);
        await tester.pumpAndSettle();
        await showCard();
        await tap(inCard('Ver votação'));
        await tap(find.text('A evidência é inconsistente'));
        expect(find.text('2 de 3 votos necessários'), findsOneWidget);
        expect(score(), 710);
        await tap(find.text('Fechar'));
        select(DemoIds.joao);
        await tester.pumpAndSettle();
        await showCard();
        await tap(inCard('Ver votação'));
        await tap(find.text('A atividade parece válida'));
        expect(find.text('Atividade invalidada pela votação.'), findsOneWidget);
        expect(find.text('A evidência é inconsistente'), findsNothing);
        expect(score(), 0);
        expect(container.read(votesForReportProvider(report.id)), hasLength(3));
        await tap(find.text('Fechar'));
        expect(inCard('0 pontos'), findsOneWidget);
        expect(
          find.descendant(of: card, matching: find.textContaining('Rejeitada')),
          findsOneWidget,
        );
        expect(inCard('Reportar'), findsNothing);
        final ranking = find.byKey(
          ValueKey('ranking-entry-${DemoIds.competition}-${DemoIds.ana}'),
        );
        await tester.scrollUntilVisible(
          ranking,
          -300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(ranking);
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: ranking, matching: find.text('0 pontos')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
