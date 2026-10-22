import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/bootstrap/providers.dart';
import '../../core/models/models.dart';
import 'session_controller.dart';

export 'session_controller.dart';

/// Current session user (null when no one is selected).
final currentUserProvider = Provider<User?>(
  (ref) => ref.watch(sessionControllerProvider).currentUser,
);

/// Demo users available for selection (from the seeded repository).
final availableUsersProvider = Provider<List<User>>(
  (ref) => ref.watch(userRepositoryProvider).listUsers(),
);
