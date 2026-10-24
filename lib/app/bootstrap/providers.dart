import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/repositories/in_memory_repositories.dart';
import '../../core/remote/sync_engine.dart';
import '../../core/repositories/repositories.dart';
import '../../core/services/demo_seed_service.dart';
import '../../core/services/domain_services.dart';
import '../../core/services/activity_submission_service.dart';

// Repositories (in-memory implementations behind interfaces).
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => InMemoryUserRepository(),
);
final roomRepositoryProvider = Provider<RoomRepository>(
  (ref) => InMemoryRoomRepository(),
);
final competitionRepositoryProvider = Provider<CompetitionRepository>(
  (ref) => InMemoryCompetitionRepository(),
);
final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  final repository = InMemoryActivityRepository();
  ref.onDispose(repository.dispose);
  return repository;
});
final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  final repository = InMemoryModerationRepository();
  ref.onDispose(repository.dispose);
  return repository;
});
final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  final repository = InMemorySocialRepository();
  ref.onDispose(repository.dispose);
  return repository;
});
final evidenceRepositoryProvider = Provider<EvidenceRepository>(
  (ref) => InMemoryEvidenceRepository(),
);

// Domain services.
final scoringServiceProvider = Provider((ref) => const ScoringService());
final paceValidationServiceProvider = Provider(
  (ref) => const PaceValidationService(),
);
final competitionStateServiceProvider = Provider(
  (ref) => const CompetitionStateService(),
);
final rankingServiceProvider = Provider(
  (ref) => RankingService(scoring: ref.watch(scoringServiceProvider)),
);
final moderationServiceProvider = Provider((ref) => const ModerationService());
final competitionResultServiceProvider = Provider(
  (ref) => CompetitionResultService(
    competitionState: ref.watch(competitionStateServiceProvider),
  ),
);
final activitySubmissionServiceProvider = Provider(
  (ref) => ActivitySubmissionService(
    competitionState: ref.watch(competitionStateServiceProvider),
    pace: ref.watch(paceValidationServiceProvider),
  ),
);

/// Clock used by the app (device time is acceptable for the demo).
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// `demo`: seeded in-memory data on one device (tests, presentation).
/// `synced`: shared data through Supabase (real multi-phone use).
enum AppMode { demo, synced }

final appModeProvider = Provider<AppMode>((ref) => AppMode.demo);

/// Supabase auth user id in synced mode; null in demo mode.
final remoteUserIdProvider = Provider<String?>((ref) => null);

/// Id factory for entities created outside repositories (reports). Null keeps
/// the deterministic sequential ids of demo mode.
final newIdProvider = Provider<IdFactory?>((ref) => null);

/// Resolves a remote evidence path to a URL (synced mode only).
final evidenceUrlProvider = Provider<String Function(String path)?>(
  (ref) => null,
);

/// User-facing synchronization messages (synced mode only).
final syncMessagesProvider = Provider<Stream<String>>(
  (ref) => const Stream.empty(),
);
final syncMessageProvider = StreamProvider<String>(
  (ref) => ref.watch(syncMessagesProvider),
);

/// Latest synchronization status (synced mode); null in demo mode.
class SyncStatusNotifier extends Notifier<SyncStatus?> {
  @override
  SyncStatus? build() => null;

  void set(SyncStatus status) => state = status;
}

final syncStatusProvider = NotifierProvider<SyncStatusNotifier, SyncStatus?>(
  SyncStatusNotifier.new,
);

/// Pull-to-refresh action: downloads fresh data in synced mode; demo data is
/// always current, so it completes immediately there.
final refreshDataProvider = Provider<Future<void> Function()>(
  (ref) => () async {},
);

/// Set when a participant just entered, so the home shows "Como funciona".
class HowItWorksFlag {
  bool pending = false;
}

final howItWorksFlagProvider = Provider<HowItWorksFlag>(
  (ref) => HowItWorksFlag(),
);

/// Bumped after the local cache is rebuilt from the server, so readers of
/// rooms, competitions and users query their repositories again.
class SyncRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final syncRevisionProvider = NotifierProvider<SyncRevision, int>(
  SyncRevision.new,
);

final demoSeedServiceProvider = Provider(
  (ref) => DemoSeedService(
    users: ref.watch(userRepositoryProvider),
    rooms: ref.watch(roomRepositoryProvider),
    competitions: ref.watch(competitionRepositoryProvider),
    activities: ref.watch(activityRepositoryProvider),
    moderation: ref.watch(moderationRepositoryProvider),
    evidence: ref.watch(evidenceRepositoryProvider),
    scoring: ref.watch(scoringServiceProvider),
  ),
);
