import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/repositories/in_memory_repositories.dart';
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
final activitySubmissionServiceProvider = Provider(
  (ref) => ActivitySubmissionService(
    competitionState: ref.watch(competitionStateServiceProvider),
    pace: ref.watch(paceValidationServiceProvider),
  ),
);

/// Clock used by the app (device time is acceptable for the demo).
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

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
