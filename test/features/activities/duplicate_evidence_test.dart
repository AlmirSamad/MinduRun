import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/app/bootstrap/providers.dart';
import 'package:mindurun/core/services/demo_seed_service.dart';
import 'package:mindurun/features/activities/activity_providers.dart';
import 'package:mindurun/features/activities/evidence_picker.dart';
import 'package:mindurun/features/session/session_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the same screenshot cannot back two activities of a competition',
    () async {
      final now = DateTime(2026, 10, 22, 12);
      final bytes = (await rootBundle.load('assets/demo/evidence_1.jpg')).buffer
          .asUint8List();
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(() => now),
          evidencePickerProvider.overrideWithValue(() async => bytes),
        ],
      );
      addTearDown(container.dispose);
      container.read(demoSeedServiceProvider).reset(now);
      final users = container.read(userRepositoryProvider);
      final session = container.read(sessionControllerProvider.notifier);
      final controller = container.read(activitiesControllerProvider.notifier);

      session.selectUser(users.getUser(DemoIds.almir)!);
      final first = await controller.selectEvidence();
      final activity = controller.submitActivity(
        competitionId: DemoIds.competition,
        distance: '5,23',
        duration: '31:45',
        pace: '06:04',
        evidence: first,
      );
      expect(activity.evidenceHash, hasLength(64));

      // Another participant re-selecting the same image is blocked early.
      session.selectUser(users.getUser(DemoIds.ana)!);
      final again = await controller.selectEvidence();
      expect(
        () => controller.preview(
          competitionId: DemoIds.competition,
          distance: '5,23',
          duration: '31:45',
          pace: '06:04',
          evidence: again,
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            'Este print já foi usado em outra atividade desta competição.',
          ),
        ),
      );
    },
  );
}
