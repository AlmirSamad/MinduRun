import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/app/app.dart';
import 'package:mindurun/app/bootstrap/providers.dart';
import 'package:mindurun/features/rooms/presentation/rooms_page.dart';
import 'package:mindurun/features/session/session_providers.dart';

void main() {
  testWidgets('synced mode asks for a name and hides demo-only actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [
        appModeProvider.overrideWithValue(AppMode.synced),
        remoteUserIdProvider.overrideWithValue('auth-uid-1'),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MinduRunApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Como você se chama?'), findsOneWidget);
    expect(find.byTooltip('Opções da demonstração'), findsNothing);

    await tester.tap(find.text('Começar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe um nome de 2 a 30 caracteres.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('participant-name')),
      '  Roberto  ',
    );
    await tester.tap(find.text('Começar'));
    await tester.pumpAndSettle();

    expect(find.byType(RoomsPage), findsOneWidget);
    expect(find.text('Usuário atual: Roberto'), findsOneWidget);
    expect(find.byTooltip('Trocar usuário'), findsNothing);
    expect(find.byTooltip('Opções da demonstração'), findsNothing);
    expect(container.read(currentUserProvider)!.id, 'auth-uid-1');
    expect(
      container.read(userRepositoryProvider).getUser('auth-uid-1')!.displayName,
      'Roberto',
    );
  });
}
