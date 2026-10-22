import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/app/app.dart';
import 'package:mindurun/app/bootstrap/providers.dart';
import 'package:mindurun/app/router/app_router.dart';
import 'package:mindurun/core/services/demo_seed_service.dart';
import 'package:mindurun/features/session/presentation/user_selection_page.dart';

void main() {
  for (final size in [const Size(375, 800), const Size(1400, 900)]) {
    testWidgets('create, switch, join and view members at $size', (
      tester,
    ) async {
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
      final router = container.read(appRouterProvider);
      router.go(AppRoutes.room(DemoIds.room));
      await tester.pumpAndSettle();
      expect(find.byType(UserSelectionPage), findsOneWidget);
      await tester.tap(find.text('Almir'));
      await tester.pumpAndSettle();
      expect(find.text('Minhas salas'), findsOneWidget);
      expect(find.text('Corrida do Mindu'), findsOneWidget);
      final bounds = tester.getRect(find.byType(Scaffold));
      expect(bounds.width, lessThanOrEqualTo(480));
      expect(bounds.center.dx, size.width / 2);
      await tester.tap(find.text('Criar sala'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Criar'));
      await tester.pumpAndSettle();
      expect(
        find.text('O nome deve ter de 3 a 40 caracteres.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byType(TextFormField),
        '  Corrida de Domingo  ',
      );
      await tester.tap(find.text('Criar'));
      await tester.pumpAndSettle();
      expect(find.text('Corrida de Domingo'), findsOneWidget);
      final room = container.read(roomRepositoryProvider).listRooms().last;
      await tester.tap(find.text('Corrida de Domingo'));
      await tester.pumpAndSettle();
      expect(find.text(room.inviteCode), findsOneWidget);
      expect(find.text('Criador: Almir'), findsOneWidget);
      expect(find.text('Proprietário'), findsOneWidget);
      expect(find.text('Membros (1)'), findsOneWidget);
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Trocar usuário'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ana'));
      await tester.pumpAndSettle();
      expect(find.text('Corrida de Domingo'), findsNothing);
      router.go(AppRoutes.room(room.id));
      await tester.pumpAndSettle();
      expect(
        find.text('Sala não encontrada ou você não participa dela.'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Entrar com código'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'INVALID');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(find.text('Sala não encontrada.'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField),
        ' ${room.inviteCode.toLowerCase()} ',
      );
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(find.text('Corrida de Domingo'), findsOneWidget);
      await tester.tap(find.text('Corrida de Domingo'));
      await tester.pumpAndSettle();
      expect(find.text('Membros (2)'), findsOneWidget);
      expect(find.text('Almir'), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Proprietário'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
