import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';

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
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
