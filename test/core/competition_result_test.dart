import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/core/models/models.dart';
import 'package:mindurun/core/services/domain_services.dart';

void main() {
  const service = CompetitionResultService();
  final start = DateTime(2026, 10, 30);
  final end = DateTime(2026, 11, 6);
  final competition = Competition(
    id: 'c1',
    roomId: 'r1',
    name: 'Desafio',
    startsAt: start,
    endsAt: end,
    status: CompetitionStatus.active,
    participantIds: const ['a', 'b', 'c', 'd'],
  );

  RankingEntry entry(int position, String id, int score, double km) =>
      RankingEntry(
        position: position,
        userId: id,
        score: score,
        acceptedDistanceKm: km,
        activityCount: score > 0 ? 1 : 0,
        underReviewCount: 0,
      );

  final ranking = [
    entry(1, 'a', 1000, 10),
    entry(2, 'b', 700, 7),
    entry(3, 'c', 500, 5),
    entry(4, 'd', 0, 0),
  ];

  test('no result before the competition finishes', () {
    expect(
      service.result(
        competition: competition,
        now: end.subtract(const Duration(minutes: 1)),
        ranking: ranking,
        openReportCount: 0,
      ),
      isNull,
    );
    expect(
      service.result(
        competition: competition.copyWith(status: CompetitionStatus.cancelled),
        now: end.add(const Duration(days: 1)),
        ranking: ranking,
        openReportCount: 0,
      ),
      isNull,
    );
  });

  test('winner and podium of a finished competition', () {
    final result = service.result(
      competition: competition,
      now: end,
      ranking: ranking,
      openReportCount: 0,
    )!;
    expect(result.winnerIds, ['a']);
    expect(result.podium.map((e) => e.userId), ['a', 'b', 'c']);
    expect(result.isFinal, isTrue);
  });

  test('full tie on score and distance shares the victory', () {
    final result = service.result(
      competition: competition,
      now: end,
      ranking: [
        entry(1, 'a', 500, 5),
        entry(2, 'b', 500, 5),
        entry(3, 'c', 500, 4),
      ],
      openReportCount: 0,
    )!;
    expect(result.winnerIds, ['a', 'b']);
  });

  test('nobody scoring means no winner; open reports keep it provisional', () {
    final result = service.result(
      competition: competition,
      now: end,
      ranking: [entry(1, 'a', 0, 0), entry(2, 'b', 0, 0)],
      openReportCount: 2,
    )!;
    expect(result.winnerIds, isEmpty);
    expect(result.podium, isEmpty);
    expect(result.isFinal, isFalse);
  });
}
