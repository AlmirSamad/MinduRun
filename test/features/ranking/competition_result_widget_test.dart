import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/app/app.dart';
import 'package:mindurun/app/bootstrap/providers.dart';
import 'package:mindurun/app/router/app_router.dart';
import 'package:mindurun/core/services/demo_seed_service.dart';
import 'package:mindurun/features/session/session_providers.dart';

void main() {
  testWidgets('finished competition shows a provisional winner and survives '
      'leaving and returning to the page', (tester) async {
    tester.view.physicalSize = const Size(375, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final seededAt = DateTime(2026, 10, 22, 12);
    var now = seededAt;
    final container = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(() => now)],
    );
    addTearDown(container.dispose);
    container.read(demoSeedServiceProvider).reset(seededAt);
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
    final router = container.read(appRouterProvider);
    router.go(AppRoutes.competition(DemoIds.competition));
    await tester.pumpAndSettle();
    expect(find.text('Resultado provisório'), findsNothing);
    expect(find.text('Resultado final'), findsNothing);

    // After the end, the seeded open report keeps the result provisional.
    now = seededAt.add(const Duration(days: 7));
    router.go(AppRoutes.room(DemoIds.room));
    await tester.pumpAndSettle();
    router.push(AppRoutes.competition(DemoIds.competition));
    await tester.pumpAndSettle();
    expect(find.text('Resultado provisório'), findsOneWidget);
    expect(find.text('Campeão: João'), findsOneWidget);
    expect(
      find.text('1 denúncia ainda em votação pode alterar o resultado.'),
      findsOneWidget,
    );

    router.push(AppRoutes.room(DemoIds.room));
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('Campeão: João'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
