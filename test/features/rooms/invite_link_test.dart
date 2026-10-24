import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/app/app.dart';
import 'package:mindurun/app/bootstrap/providers.dart';
import 'package:mindurun/app/router/app_router.dart';
import 'package:mindurun/core/services/demo_seed_service.dart';
import 'package:mindurun/features/rooms/presentation/room_details_page.dart';
import 'package:mindurun/features/rooms/room_providers.dart';
import 'package:mindurun/features/session/session_providers.dart';

void main() {
  testWidgets('invite link opened while signed out joins after entering', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(demoSeedServiceProvider).reset(DateTime.now());
    final users = container.read(userRepositoryProvider);
    final session = container.read(sessionControllerProvider.notifier);
    session.selectUser(users.getUser(DemoIds.almir)!);
    final room = container
        .read(roomsControllerProvider.notifier)
        .createRoom('Treino de Sábado');
    session.logout();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MinduRunApp(),
      ),
    );
    final router = container.read(appRouterProvider);
    router.go(AppRoutes.join(room.inviteCode.toLowerCase()));
    await tester.pumpAndSettle();
    expect(container.read(pendingInviteProvider).code, isNotNull);

    await tester.tap(find.text('Ana'));
    await tester.pumpAndSettle();

    expect(find.byType(RoomDetailsPage), findsOneWidget);
    expect(find.text('Treino de Sábado'), findsWidgets);
    expect(
      container.read(roomRepositoryProvider).getRoom(room.id)!.memberIds,
      contains(DemoIds.ana),
    );
    expect(container.read(pendingInviteProvider).code, isNull);
  });

  testWidgets('unknown invite code offers a retry', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(demoSeedServiceProvider).reset(DateTime.now());
    container
        .read(sessionControllerProvider.notifier)
        .selectUser(
          container.read(userRepositoryProvider).getUser(DemoIds.ana)!,
        );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MinduRunApp(),
      ),
    );
    container.read(appRouterProvider).go(AppRoutes.join('ZZZ999'));
    await tester.pumpAndSettle();
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
