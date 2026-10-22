import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/core/models/models.dart';
import 'package:mindurun/core/services/domain_services.dart';

Activity run(
  String id,
  String user,
  int score, {
  String competitionId = 'a',
  double distance = 1,
  ActivityModerationStatus status = ActivityModerationStatus.published,
}) => Activity(
  id: id,
  competitionId: competitionId,
  userId: user,
  distanceKm: distance,
  durationSeconds: 360,
  averagePaceSecondsPerKm: 360,
  evidenceRef: const EvidenceRef.asset('assets/demo/evidence_1.jpg'),
  score: score,
  moderationStatus: status,
  submittedAt: DateTime(2026),
);

void main() {
  const service = RankingService();
  test(
    'aggregates stored historical scores instead of recalculating by distance',
    () {
      final entries = service.buildRanking(
        competitionId: 'a',
        participantIds: ['almir'],
        activities: [run('1', 'almir', 500), run('2', 'almir', 300)],
      );
      expect(entries.single.score, 800); // Distances total only 2 km.
      expect(entries.single.activityCount, 2);
      final decimal = service.buildRanking(
        competitionId: 'a',
        participantIds: ['almir'],
        activities: [run('1', 'almir', 523), run('2', 'almir', 477)],
      );
      expect(decimal.single.score, 1000);
    },
  );
  test('orders multiple users and retains participants with no activity', () {
    final entries = service.buildRanking(
      competitionId: 'a',
      participantIds: ['ana', 'almir', 'carlos', 'joao'],
      activities: [
        run('1', 'almir', 1000),
        run('2', 'ana', 700),
        run('3', 'carlos', 900),
      ],
    );
    expect(entries.map((entry) => entry.userId), [
      'almir',
      'carlos',
      'ana',
      'joao',
    ]);
    expect(entries.last.score, 0);
    expect(entries.last.activityCount, 0);
  });
  test(
    'filters other competitions and users outside the participant snapshot',
    () {
      final entries = service.buildRanking(
        competitionId: 'a',
        participantIds: ['almir', 'ana'],
        activities: [
          run('1', 'almir', 500),
          run('2', 'almir', 9999, competitionId: 'b'),
          run('3', 'late-member', 8888),
        ],
      );
      expect(entries.map((entry) => entry.userId), ['almir', 'ana']);
      expect(entries.map((entry) => entry.score), [500, 0]);
      expect(entries.first.activityCount, 1);
    },
  );
  test('published and under-review contribute; rejected contributes zero', () {
    final entries = service.buildRanking(
      competitionId: 'a',
      participantIds: ['almir'],
      activities: [
        run('1', 'almir', 500, distance: 5),
        run(
          '2',
          'almir',
          300,
          distance: 3,
          status: ActivityModerationStatus.rejected,
        ),
        run(
          '3',
          'almir',
          200,
          distance: 2,
          status: ActivityModerationStatus.underReview,
        ),
      ],
    );
    expect(entries.single.score, 700);
    expect(entries.single.acceptedDistanceKm, 7);
    expect(entries.single.hasUnderReview, isTrue);
    expect(entries.single.underReviewCount, 1);
  });
  test('future rejection recalculates 800 to 500 without deleting history', () {
    final published = run('2', 'almir', 300);
    final first = run('1', 'almir', 500);
    expect(
      service
          .buildRanking(
            competitionId: 'a',
            participantIds: ['almir'],
            activities: [first, published],
          )
          .single
          .score,
      800,
    );
    final after = service.buildRanking(
      competitionId: 'a',
      participantIds: ['almir'],
      activities: [
        first,
        published.copyWith(moderationStatus: ActivityModerationStatus.rejected),
      ],
    );
    expect(after.single.score, 500);
    expect(after.single.activityCount, 2);
  });
  test('exact ties retain snapshot order and sequential ordinal positions', () {
    final activities = [
      run('1', 'a', 500),
      run('2', 'b', 500),
      run('3', 'c', 500),
    ];
    for (final input in [activities, activities.reversed.toList()]) {
      final entries = service.buildRanking(
        competitionId: 'a',
        participantIds: ['b', 'c', 'a'],
        activities: input,
      );
      expect(entries.map((entry) => entry.userId), ['b', 'c', 'a']);
      expect(entries.map((entry) => entry.position), [1, 2, 3]);
    }
  });
  test('empty competitions and all-zero participants remain deterministic', () {
    expect(
      service.buildRanking(
        competitionId: 'a',
        participantIds: [],
        activities: [run('1', 'a', 500)],
      ),
      isEmpty,
    );
    final zero = service.buildRanking(
      competitionId: 'a',
      participantIds: ['b', 'a'],
      activities: [],
    );
    expect(zero.map((entry) => entry.userId), ['b', 'a']);
    expect(zero.map((entry) => entry.score), [0, 0]);
    expect(zero.map((entry) => entry.position), [1, 2]);
  });
}
