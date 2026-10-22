import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/app/app.dart';
import 'package:mindurun/app/bootstrap/providers.dart';
import 'package:mindurun/app/router/app_router.dart';
import 'package:mindurun/core/models/models.dart';
import 'package:mindurun/core/services/demo_seed_service.dart';
import 'package:mindurun/features/competitions/competition_providers.dart';
import 'package:mindurun/features/competitions/presentation/competition_widgets.dart';
import 'package:mindurun/features/rooms/room_providers.dart';
import 'package:mindurun/features/session/presentation/user_selection_page.dart';
import 'package:mindurun/features/session/session_providers.dart';

void main() {
  for (final size in const [Size(375, 800), Size(1400, 900)]) {
    testWidgets(
      'confirmed reset returns to selection and cancel keeps changes at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.read(demoSeedServiceProvider).reset(DateTime.now());
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MinduRunApp(),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Almir'));
        await tester.pumpAndSettle();
        container
            .read(roomsControllerProvider.notifier)
            .createRoom('Temporária');
        await tester.pumpAndSettle();
        Future<void> openReset() async {
          await tester.tap(find.byTooltip('Opções da demonstração'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Resetar demonstração'));
          await tester.pumpAndSettle();
        }

        await openReset();
        expect(find.text('Resetar demonstração?'), findsOneWidget);
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(find.text('Temporária'), findsOneWidget);
        expect(container.read(currentUserProvider), isNotNull);
        await openReset();
        // Invoke the same callback twice before a frame; after the first action
        // the modal route is already removed from pointer hit testing.
        final reset = tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Resetar'))
            .onPressed!;
        reset();
        reset();
        await tester.pumpAndSettle();
        expect(find.byType(UserSelectionPage), findsOneWidget);
        expect(container.read(currentUserProvider), isNull);
        expect(
          container.read(roomRepositoryProvider).listRooms(),
          hasLength(1),
        );
        await tester.tap(find.text('Ana'));
        await tester.pumpAndSettle();
        expect(find.text('Corrida do Mindu'), findsOneWidget);
        expect(find.text('Temporária'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'empty states, duplicate create, unknown IDs and protected routes at $size',
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
        const newcomer = User(id: 'new', displayName: 'Novo participante');
        container.read(userRepositoryProvider).addUser(newcomer);
        container.read(sessionControllerProvider.notifier).selectUser(newcomer);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MinduRunApp(),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Você ainda não participa de nenhuma sala.'),
          findsOneWidget,
        );
        expect(find.text('Entrar com código'), findsOneWidget);
        await tester.tap(find.text('Criar sala'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField), 'Nova sala');
        final create = tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Criar'))
            .onPressed!;
        create();
        create();
        await tester.pumpAndSettle();
        expect(container.read(currentUserRoomsProvider), hasLength(1));
        final room = container.read(currentUserRoomsProvider).single;
        final router = container.read(appRouterProvider);
        router.go(AppRoutes.room(room.id));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(RoomCompetitionsSection));
        expect(find.text('Nenhuma competição nesta sala.'), findsOneWidget);
        expect(find.text('Criar competição'), findsOneWidget);
        final comp = container
            .read(competitionsControllerProvider.notifier)
            .createCompetition(
              roomId: room.id,
              name: 'Nova competição',
              startsAt: now.subtract(const Duration(hours: 1)),
              endsAt: now.add(const Duration(days: 1)),
            );
        router.go(AppRoutes.competition(comp.id));
        await tester.pumpAndSettle();
        expect(find.text('Registrar atividade'), findsOneWidget);
        expect(
          find.text('Ainda não há pontuação nesta competição.'),
          findsOneWidget,
        );
        expect(find.text('0 pontos'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Nenhuma atividade registrada ainda.'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          find.text('Nenhuma atividade registrada ainda.'),
          findsOneWidget,
        );
        expect(find.text('Ver votação'), findsNothing);
        for (final path in [
          AppRoutes.room('invalid'),
          AppRoutes.competition('invalid'),
        ]) {
          router.go(path);
          await tester.pumpAndSettle();
          expect(find.textContaining('não encontrada'), findsOneWidget);
          await tester.tap(find.byTooltip('Voltar'));
          await tester.pumpAndSettle();
          expect(find.text('Minhas salas'), findsOneWidget);
        }
        container.read(sessionControllerProvider.notifier).logout();
        router.go(AppRoutes.competition(comp.id));
        await tester.pumpAndSettle();
        expect(find.byType(UserSelectionPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'all bundled seed evidence is registered, loadable and decodable',
    (tester) async {
      await tester.runAsync(() async {
        for (final asset in DemoAssets.evidence) {
          final bytes = await rootBundle.load(asset);
          expect(bytes.lengthInBytes, greaterThan(0));
          final codec = await ui.instantiateImageCodec(
            bytes.buffer.asUint8List(),
          );
          final frame = await codec.getNextFrame();
          expect(frame.image.width, greaterThan(0));
          expect(frame.image.height, greaterThan(0));
          frame.image.dispose();
          codec.dispose();
        }
      });
    },
  );
}
