import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/core/models/models.dart';
import 'package:mindurun/core/repositories/in_memory_repositories.dart';
import 'package:mindurun/core/services/activity_submission_service.dart';

void main() {
  const policy = ActivitySubmissionService();
  final now = DateTime(2026, 10, 22, 12);
  Competition competition(
    DateTime start,
    DateTime end, {
    CompetitionStatus status = CompetitionStatus.active,
  }) => Competition(
    id: 'c',
    roomId: 'r',
    name: 'Desafio',
    startsAt: start,
    endsAt: end,
    status: status,
    participantIds: const ['almir'],
  );
  final active = competition(
    now.subtract(const Duration(days: 1)),
    now.add(const Duration(days: 1)),
  );
  test('participant can submit only while active', () {
    expect(policy.authorizationError(active, 'almir', now), isNull);
    expect(policy.authorizationError(active, null, now), isNotNull);
    expect(policy.authorizationError(active, 'ana', now), isNotNull);
    expect(policy.authorizationError(null, 'almir', now), isNotNull);
    expect(policy.authorizationError(active, 'almir', active.startsAt), isNull);
    expect(
      policy.authorizationError(
        active,
        'almir',
        active.startsAt.subtract(const Duration(seconds: 1)),
      ),
      isNotNull,
    );
    expect(
      policy.authorizationError(active, 'almir', active.endsAt),
      isNotNull,
    );
    expect(
      policy.authorizationError(
        active.copyWith(status: CompetitionStatus.cancelled),
        'almir',
        now,
      ),
      isNotNull,
    );
  });
  test('inconsistent data is rejected by the existing pace rule', () {
    expect(
      policy.metricsError(
        distanceKm: 5,
        durationSeconds: 1800,
        averagePaceSecondsPerKm: 480,
      ),
      isNotNull,
    );
    expect(
      policy.metricsError(
        distanceKm: 5.23,
        durationSeconds: 1905,
        averagePaceSecondsPerKm: 364,
      ),
      isNull,
    );
  });
  test('repository generates IDs, preserves submission data and isolates competitions', () {
    final repo = InMemoryActivityRepository();
    final evidence = InMemoryEvidenceRepository();
    final ref = evidence.registerAsset('assets/demo/evidence_1.jpg');
    Activity create(String competitionId, DateTime submittedAt) =>
        repo.createLocalActivity(
          competitionId: competitionId,
          userId: 'almir',
          distanceKm: 5.23,
          durationSeconds: 1905,
          averagePaceSecondsPerKm: 364,
          evidenceRef: ref,
          score: 523,
          submittedAt: submittedAt,
        );
    final first = create('a', now);
    final second = create('a', now.add(const Duration(seconds: 1)));
    final other = create('b', now);
    expect(first.id, isNot(second.id));
    expect(repo.getActivity(first.id), same(first));
    expect(first.competitionId, 'a');
    expect(first.userId, 'almir');
    expect(first.distanceKm, 5.23);
    expect(first.durationSeconds, 1905);
    expect(first.averagePaceSecondsPerKm, 364);
    expect(evidence.exists(first.evidenceRef), isTrue);
    expect(first.score, 523);
    expect(first.moderationStatus, ActivityModerationStatus.published);
    expect(first.submittedAt, now);
    expect(repo.listCompetitionActivities('a'), [second, first]);
    expect(repo.listCompetitionActivities('b'), [other]);
  });
  test('memory evidence owns an immutable copy and clears on reset', () {
    final repo = InMemoryEvidenceRepository();
    final bytes = Uint8List.fromList([1, 2, 3]);
    final ref = repo.storeBytes(bytes);
    bytes[0] = 99;
    expect(repo.getBytes(ref), [1, 2, 3]);
    expect(() => repo.getBytes(ref)![0] = 99, throwsUnsupportedError);
    repo.clear();
    expect(repo.exists(ref), isFalse);
  });
}
