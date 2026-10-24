import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';
import 'app_config.dart';
import 'providers.dart';
import 'synced_startup.dart';
import '../../features/activities/evidence_picker.dart';
import '../../features/activities/evidence_image_picker.dart';

/// Starts the app: Supabase-synced when configured at build time, otherwise
/// the local demo with seeded data.
void bootstrap() {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.isSynced) {
    runApp(const SyncedStartup());
    return;
  }
  final container = ProviderContainer(
    overrides: [evidencePickerProvider.overrideWithValue(pickScreenshotBytes)],
  );
  final now = container.read(clockProvider)();
  container.read(demoSeedServiceProvider).reset(now);
  runApp(
    UncontrolledProviderScope(container: container, child: const MinduRunApp()),
  );
}
