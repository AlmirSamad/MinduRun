import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/bootstrap/providers.dart';
import '../../core/models/models.dart';
import '../../core/services/profile_rules.dart';

/// In-memory local session (no real authentication).
class SessionState {
  const SessionState({this.currentUser});

  final User? currentUser;

  bool get isAuthenticated => currentUser != null;
}

/// Controls the simulated local session.
class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() => const SessionState();

  void selectUser(User user) => state = SessionState(currentUser: user);

  void logout() => state = const SessionState();

  /// Synced mode: creates or renames this phone's profile and signs it in.
  User saveProfile(String name) {
    final error = ProfileRules.validateName(name);
    if (error != null) throw ArgumentError(error);
    final id = ref.read(remoteUserIdProvider);
    if (id == null) throw StateError('Sessão do servidor indisponível.');
    final user = User(id: id, displayName: name.trim());
    ref.read(userRepositoryProvider).addUser(user);
    ref.read(syncRevisionProvider.notifier).bump();
    selectUser(user);
    return user;
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
