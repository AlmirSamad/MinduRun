import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';
import 'providers.dart';
import '../../features/activities/evidence_picker.dart';
import '../../features/activities/evidence_image_picker.dart';

/// Creates the provider container, loads the demo seed and starts the app.
void bootstrap() {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer(
    overrides: [evidencePickerProvider.overrideWithValue(pickScreenshotBytes)],
  );
  final now = container.read(clockProvider)();
  container.read(demoSeedServiceProvider).reset(now);
  runApp(
    UncontrolledProviderScope(container: container, child: const MinduRunApp()),
  );
}
