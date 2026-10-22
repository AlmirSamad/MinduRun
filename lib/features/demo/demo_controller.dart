import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/bootstrap/providers.dart';
import '../activities/activity_providers.dart';
import '../competitions/competition_providers.dart';
import '../moderation/moderation_providers.dart';
import '../rooms/room_providers.dart';
import '../session/session_providers.dart';

/// Coordinates the existing seed reset and refreshes repository readers.
class DemoController extends Notifier<void> {
  @override
  void build() {}

  void reset() {
    ref.read(sessionControllerProvider.notifier).logout();
    ref.read(demoSeedServiceProvider).reset(ref.read(clockProvider)());
    ref.invalidate(availableUsersProvider);
    ref.invalidate(roomsControllerProvider);
    ref.invalidate(competitionsControllerProvider);
    ref.invalidate(activitiesControllerProvider);
    ref.invalidate(moderationControllerProvider);
  }
}

final demoControllerProvider = NotifierProvider<DemoController, void>(
  DemoController.new,
);
