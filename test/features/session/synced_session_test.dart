import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/app/app.dart';
import 'package:mindurun/app/bootstrap/providers.dart';
import 'package:mindurun/core/services/profile_rules.dart';
import 'package:mindurun/features/rooms/presentation/rooms_page.dart';
import 'package:mindurun/features/session/session_providers.dart';

void main() {
  testWidgets('synced mode asks for a name and hides demo-only actions', (
    tester,
  ) async {
    // Tall enough for the whole entry form (consent included) without scrolling.
    tester.view.physicalSize = const Size(375, 1100);
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

    await tester.ensureVisible(find.text('Começar'));
    await tester.tap(find.text('Começar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe um nome de 2 a 30 caracteres.'), findsOneWidget);

    expect(find.text('Confirme para participar do teste.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('participant-name')),
      '  Roberto  ',
    );
    await tester.ensureVisible(find.text('Começar'));
    await tester.tap(find.text('Começar'));
    await tester.pumpAndSettle();
    // A valid name is not enough without the privacy consent.
    expect(find.byType(RoomsPage), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('privacy-consent')));
    await tester.tap(find.byKey(const Key('privacy-consent')));
    await tester.pumpAndSettle();
    expect(find.text('Confirme para participar do teste.'), findsNothing);
    await tester.ensureVisible(find.text('Começar'));
    await tester.tap(find.text('Começar'));
    await tester.pumpAndSettle();

    expect(find.byType(RoomsPage), findsOneWidget);
    // First entry shows the rules once.
    expect(find.text('Como funciona'), findsWidgets);
    await tester.tap(find.text('Entendi'));
    await tester.pumpAndSettle();
    expect(find.text('Entendi'), findsNothing);
    expect(find.text('Usuário atual: Roberto'), findsOneWidget);
    expect(find.byTooltip('Trocar usuário'), findsNothing);
    expect(find.byTooltip('Opções da demonstração'), findsNothing);
    expect(container.read(currentUserProvider)!.id, 'auth-uid-1');
    expect(
      container.read(userRepositoryProvider).getUser('auth-uid-1')!.displayName,
      'Roberto',
    );

    // Rename keeps the same account id and updates the shown name.
    await tester.tap(find.byTooltip('Alterar nome'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('rename-field')), 'R');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe um nome de 2 a 30 caracteres.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('rename-field')), 'Roberto N.');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Usuário atual: Roberto N.'), findsOneWidget);
    expect(container.read(currentUserProvider)!.id, 'auth-uid-1');
    expect(container.read(userRepositoryProvider).listUsers(), hasLength(1));
  });

  test('profile names are trimmed and limited to 2–30 characters', () {
    expect(ProfileRules.validateName(' A '), isNotNull);
    expect(ProfileRules.validateName('Ana'), isNull);
    expect(ProfileRules.validateName('x' * 30), isNull);
    expect(ProfileRules.validateName('x' * 31), isNotNull);
    expect(ProfileRules.validateName(null), isNotNull);
  });
}
