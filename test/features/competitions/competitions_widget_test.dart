import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/app/app.dart';
import 'package:mindurun/app/bootstrap/providers.dart';
import 'package:mindurun/app/router/app_router.dart';
import 'package:mindurun/core/models/models.dart';
import 'package:mindurun/core/services/demo_seed_service.dart';
import 'package:mindurun/features/competitions/presentation/competition_widgets.dart';
import 'package:mindurun/features/competitions/presentation/competition_details_page.dart';
import 'package:mindurun/features/session/presentation/user_selection_page.dart';

bool _isKnownMaterialTimePickerInputOverflow(
  FlutterErrorDetails details,
  TimePickerDialog picker,
) {
  // Flutter 3.47.7's native input-mode Column needs 256 px with the test
  // font, but TimePickerDialog constrains it to 252 px. Match the actual
  // RenderFlex inside this picker, never an application form or other error.
  if (details.library != 'rendering library' ||
      details.exception is! FlutterError ||
      details.exception.toString() !=
          'A RenderFlex overflowed by 4.0 pixels on the bottom.') {
    return false;
  }
  for (final node
      in details.informationCollector?.call() ?? const <DiagnosticsNode>[]) {
    final render = node.value;
    if (render is! RenderFlex || render.direction != Axis.vertical) continue;
    final creator = render.debugCreator;
    if (creator is! DebugCreator) continue;
    final widget = creator.element.widget;
    if (widget is Column &&
        widget.mainAxisAlignment == MainAxisAlignment.spaceBetween &&
        widget.mainAxisSize == MainAxisSize.min &&
        widget.crossAxisAlignment == CrossAxisAlignment.start &&
        render.size == const Size(248, 252) &&
        render.constraints ==
            const BoxConstraints(
              minWidth: 248,
              maxWidth: 248,
              minHeight: 216,
              maxHeight: 252,
            ) &&
        identical(
          creator.element.findAncestorWidgetOfExactType<TimePickerDialog>(),
          picker,
        )) {
      return true;
    }
  }
  return false;
}

Future<void> pickDateTime(
  WidgetTester tester,
  Key field,
  DateTime value,
) async {
  await tester.tap(find.byKey(field));
  await tester.pumpAndSettle();
  expect(find.byType(DatePickerDialog), findsOneWidget);
  expect(tester.takeException(), isNull, reason: 'Opening the date picker');
  final localization = MaterialLocalizations.of(
    tester.element(find.byType(DatePickerDialog)),
  );
  await tester.tap(find.byTooltip(localization.inputDateModeButtonLabel));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: 'Date picker input mode');
  await tester.enterText(
    find.descendant(
      of: find.byType(DatePickerDialog),
      matching: find.byType(TextFormField),
    ),
    localization.formatCompactDate(value),
  );
  await tester.tap(find.text('Confirmar'));
  await tester.pumpAndSettle();
  expect(find.byType(TimePickerDialog), findsOneWidget);
  expect(tester.takeException(), isNull, reason: 'Opening the time picker');
  final timeLocalization = MaterialLocalizations.of(
    tester.element(find.byType(TimePickerDialog)),
  );
  final picker = tester.widget<TimePickerDialog>(find.byType(TimePickerDialog));
  final previousErrorHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    if (!_isKnownMaterialTimePickerInputOverflow(details, picker)) {
      previousErrorHandler!(details);
    }
  };
  try {
    await tester.tap(find.byTooltip(timeLocalization.inputTimeModeButtonLabel));
    await tester.pumpAndSettle();
  } finally {
    FlutterError.onError = previousErrorHandler;
  }
  expect(tester.takeException(), isNull, reason: 'Time picker input mode');
  final fields = find.descendant(
    of: find.byType(TimePickerDialog),
    matching: find.byType(TextFormField),
  );
  await tester.enterText(fields.at(0), value.hour.toString().padLeft(2, '0'));
  await tester.enterText(fields.at(1), value.minute.toString().padLeft(2, '0'));
  await tester.tap(find.text('Confirmar'));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  for (final size in const [Size(375, 800), Size(1400, 900)]) {
    testWidgets('owner creates and member views competition at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final now = DateTime(2026, 10, 22, 12);
      final container = ProviderContainer(
        overrides: [clockProvider.overrideWithValue(() => now)],
      );
      addTearDown(container.dispose);
      container.read(demoSeedServiceProvider).reset(now);
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
      expect(find.byType(UserSelectionPage), findsOneWidget);
      await tester.tap(find.text('Almir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Corrida do Mindu'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(RoomCompetitionsSection));
      await tester.pumpAndSettle();
      expect(find.text('Desafio Semanal do Mindu'), findsOneWidget);
      expect(find.text('ATIVA'), findsOneWidget);
      await tester.ensureVisible(find.text('Criar competição'));
      await tester.tap(find.text('Criar competição'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Criar'));
      await tester.pumpAndSettle();
      expect(
        find.text('O nome deve ter de 3 a 50 caracteres.'),
        findsOneWidget,
      );
      expect(find.text('Informe início e término.'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField),
        '  Desafio de Domingo  ',
      );
      final start = DateTime(2026, 10, 23, 8);
      await pickDateTime(tester, const Key('competition-start'), start);
      await pickDateTime(tester, const Key('competition-end'), start);
      await tester.tap(find.text('Criar'));
      await tester.pumpAndSettle();
      expect(
        find.text('O término deve ser posterior ao início.'),
        findsOneWidget,
      );
      await pickDateTime(
        tester,
        const Key('competition-end'),
        DateTime(2026, 10, 27, 20),
      );
      await tester.tap(find.text('Criar'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Desafio de Domingo'));
      await tester.pumpAndSettle();
      expect(find.text('Desafio de Domingo'), findsOneWidget);
      expect(find.text('AGENDADA'), findsOneWidget);
      final competition = container
          .read(competitionRepositoryProvider)
          .listCompetitions()
          .last;
      expect(competition.startsAt, start);
      final card = find.ancestor(
        of: find.text('Desafio de Domingo'),
        matching: find.byType(Card),
      );
      final open = find.descendant(
        of: card,
        matching: find.text('Ver competição'),
      );
      await tester.ensureVisible(open);
      await tester.tap(open);
      await tester.pumpAndSettle();
      expect(find.byType(CompetitionDetailsPage), findsOneWidget);
      expect(find.text('AGENDADA'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('competition-participants')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Participantes (5)'), findsOneWidget);
      for (final name in ['Almir', 'Ana', 'Carlos', 'João', 'Marina']) {
        final participant = find.descendant(
          of: find.byKey(const Key('competition-participants')),
          matching: find.text(name),
        );
        await tester.ensureVisible(participant);
        expect(participant, findsOneWidget);
      }
      final bounds = tester.getRect(find.byType(Scaffold));
      expect(bounds.width, lessThanOrEqualTo(MobileShell.maxWidth));
      expect(bounds.center.dx, size.width / 2);
      router.go(AppRoutes.home);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Trocar usuário'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ana'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Corrida do Mindu'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(RoomCompetitionsSection));
      await tester.pumpAndSettle();
      expect(find.text('Criar competição'), findsNothing);
      expect(find.text('Desafio de Domingo'), findsOneWidget);
      router.push(AppRoutes.competition(competition.id));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('competition-participants')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Participantes (5)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'badge recalculates time on rebuild and respects cancelled status',
    (tester) async {
      var now = DateTime(2026, 10, 22, 12);
      final start = now.add(const Duration(hours: 1));
      final end = now.add(const Duration(hours: 2));
      final competition = Competition(
        id: 'c',
        roomId: 'r',
        name: 'Desafio',
        startsAt: start,
        endsAt: end,
        status: CompetitionStatus.active,
        participantIds: const [],
      );
      final container = ProviderContainer(
        overrides: [clockProvider.overrideWithValue(() => now)],
      );
      addTearDown(container.dispose);
      Future<void> render(Competition value) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              key: ValueKey('$now-${value.status}'),
              home: Scaffold(body: CompetitionStatusBadge(competition: value)),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await render(competition);
      expect(find.text('AGENDADA'), findsOneWidget);
      now = start;
      await render(competition);
      expect(find.text('ATIVA'), findsOneWidget);
      now = end;
      await render(competition);
      expect(find.text('FINALIZADA'), findsOneWidget);
      await render(competition.copyWith(status: CompetitionStatus.cancelled));
      expect(find.text('CANCELADA'), findsOneWidget);
    },
  );
}
