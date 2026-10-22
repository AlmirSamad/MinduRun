import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/app/app.dart';
import 'package:mindurun/app/bootstrap/providers.dart';
import 'package:mindurun/app/router/app_router.dart';
import 'package:mindurun/features/session/presentation/demo_home_screen.dart';
import 'package:mindurun/features/session/presentation/user_selection_page.dart';
import 'package:mindurun/features/session/session_providers.dart';
import 'package:mindurun/features/rooms/presentation/rooms_page.dart';

void main() {
  for (final size in const [Size(375, 800), Size(1400, 900)]) {
    testWidgets('local session flow at ${size.width}px', (tester) async {
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
      expect(find.byType(UserSelectionPage), findsOneWidget);
      for (final user in container.read(userRepositoryProvider).listUsers()) {
        expect(find.text(user.displayName), findsOneWidget);
      }
      final bounds = tester.getRect(find.byType(Scaffold));
      expect(bounds.width, lessThanOrEqualTo(MobileShell.maxWidth));
      expect(bounds.center.dx, size.width / 2);
      router.go(AppRoutes.home);
      await tester.pumpAndSettle();
      expect(find.byType(UserSelectionPage), findsOneWidget);
      for (final name in ['Almir', 'Ana']) {
        await tester.tap(find.text(name));
        await tester.pumpAndSettle();
        expect(find.byType(RoomsPage), findsOneWidget);
        expect(identical(container.read(appRouterProvider), router), isTrue);
        expect(find.text('Usuário atual: $name'), findsOneWidget);
        expect(find.text('Corrida do Mindu'), findsOneWidget);
        router.push(AppRoutes.demo);
        await tester.pumpAndSettle();
        expect(find.byType(DemoHomeScreen), findsOneWidget);
        expect(find.text('Desafio Semanal do Mindu'), findsOneWidget);
        await tester.ensureVisible(find.text('1000 pts'));
        expect(find.text('1000 pts'), findsOneWidget);
        expect(tester.takeException(), isNull);
        router.go(AppRoutes.selectUser);
        await tester.pumpAndSettle();
        expect(find.byType(RoomsPage), findsOneWidget);
        await tester.tap(find.byTooltip('Trocar usuário'));
        await tester.pumpAndSettle();
        expect(find.byType(UserSelectionPage), findsOneWidget);
        expect(container.read(currentUserProvider), isNull);
        expect(tester.takeException(), isNull);
      }
    });
  }
}
