import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/session/presentation/demo_home_screen.dart';
import '../../features/session/presentation/user_selection_page.dart';
import '../../features/session/session_providers.dart';
import '../../features/rooms/presentation/rooms_page.dart';
import '../../features/rooms/presentation/join_invite_page.dart';
import '../../features/rooms/presentation/room_details_page.dart';
import '../../features/competitions/presentation/competition_details_page.dart';
import '../../features/activities/presentation/activity_submission_page.dart';

/// Route paths. Future phases add rooms, competitions, etc.
abstract final class AppRoutes {
  static const selectUser = '/select-user';
  static const home = '/home';
  static const demo = '/demo';
  static String room(String id) => '/rooms/${Uri.encodeComponent(id)}';
  static String competition(String id) =>
      '/competitions/${Uri.encodeComponent(id)}';
  static String newActivity(String id) => '${competition(id)}/activity/new';
  static String join(String code) => '/join/${Uri.encodeComponent(code)}';
  static const profile = '/profile';
}

/// Invite code opened before signing in; consumed right after entering.
class PendingInvite {
  String? code;
}

final pendingInviteProvider = Provider<PendingInvite>((ref) => PendingInvite());

final appRouterProvider = Provider<GoRouter>((ref) {
  // Refreshes redirects when the session changes, without recreating the
  // router.
  final sessionListenable = ValueNotifier<bool>(
    ref.read(sessionControllerProvider).isAuthenticated,
  );
  ref.listen(
    sessionControllerProvider,
    (_, next) => sessionListenable.value = next.isAuthenticated,
  );

  final router = GoRouter(
    initialLocation: AppRoutes.selectUser,
    refreshListenable: sessionListenable,
    redirect: (context, state) {
      final loggedIn = sessionListenable.value;
      final atSelection = state.matchedLocation == AppRoutes.selectUser;
      final invite = ref.read(pendingInviteProvider);
      if (!loggedIn && !atSelection) {
        final segments = state.uri.pathSegments;
        if (segments.length == 2 && segments.first == 'join') {
          invite.code = segments.last;
        }
        return AppRoutes.selectUser;
      }
      if (loggedIn && (atSelection || state.matchedLocation == '/')) {
        final code = invite.code;
        invite.code = null;
        return code == null ? AppRoutes.home : AppRoutes.join(code);
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AppRoutes.selectUser),
      GoRoute(
        path: AppRoutes.selectUser,
        builder: (context, state) => const UserSelectionPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const RoomsPage(),
      ),
      GoRoute(
        path: '/rooms/:roomId',
        builder: (context, state) =>
            RoomDetailsPage(roomId: state.pathParameters['roomId']!),
      ),
      GoRoute(
        path: AppRoutes.demo,
        builder: (context, state) => const DemoHomeScreen(),
      ),
      GoRoute(
        path: '/competitions/:competitionId',
        builder: (context, state) => CompetitionDetailsPage(
          competitionId: state.pathParameters['competitionId']!,
        ),
      ),
      GoRoute(
        path: '/competitions/:competitionId/activity/new',
        builder: (context, state) => ActivitySubmissionPage(
          competitionId: state.pathParameters['competitionId']!,
        ),
      ),
      GoRoute(
        path: '/join/:code',
        builder: (context, state) =>
            JoinInvitePage(code: state.pathParameters['code']!),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    sessionListenable.dispose();
  });
  return router;
});
