import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindurun/core/models/models.dart';
import 'package:mindurun/core/remote/remote_ids.dart';
import 'package:mindurun/core/remote/remote_store.dart';
import 'package:mindurun/core/remote/sync_engine.dart';
import 'package:mindurun/core/remote/synced_repositories.dart';
import 'package:mindurun/core/repositories/in_memory_repositories.dart';

/// Records writes in order and serves a configurable snapshot.
class FakeRemoteStore implements RemoteStore {
  final calls = <String>[];
  RemoteSnapshot snapshot = const RemoteSnapshot();
  Completer<void>? gate;
  bool failWrites = false;
  bool failFetch = false;

  /// Calls (by prefix, e.g. `upload`) that fail the next N times.
  final failNext = <String, int>{};
  String? rejectWith;
  void Function()? onChange;

  Future<void> _write(String call) async {
    calls.add(call);
    await gate?.future;
    if (failWrites) throw Exception('offline');
    final prefix = call.split(':').first;
    if ((failNext[prefix] ?? 0) > 0) {
      failNext[prefix] = failNext[prefix]! - 1;
      throw Exception('offline');
    }
    if (rejectWith != null) throw RemoteRejected(rejectWith!);
  }

  @override
  Future<RemoteSnapshot> fetchAll() async {
    if (failFetch) throw Exception('offline');
    return snapshot;
  }

  @override
  Future<void> upsertProfile(User user) => _write('profile:${user.id}');
  @override
  Future<void> insertRoom(Room room) => _write('room:${room.id}');
  @override
  Future<void> insertMember(String roomId, String userId) =>
      _write('member:$roomId:$userId');
  @override
  Future<void> insertCompetition(Competition competition) =>
      _write('competition:${competition.id}');
  @override
  Future<void> insertActivity(Activity activity) =>
      _write('activity:${activity.id}');
  @override
  Future<void> joinCompetition(String competitionId) =>
      _write('join:$competitionId');
  @override
  Future<void> createReport(ActivityReport report) =>
      _write('report:${report.id}');
  @override
  Future<void> castVote(ReportVote vote) => _write('vote:${vote.id}');
  @override
  Future<void> uploadEvidence(String path, Uint8List bytes) =>
      _write('upload:$path');
  @override
  String evidenceUrl(String path) => 'https://example.test/$path';
  @override
  void Function() watch(void Function() onChange) {
    this.onChange = onChange;
    return () => this.onChange = null;
  }
}

void main() {
  late FakeRemoteStore remote;
  late SyncEngine engine;

  setUp(() {
    remote = FakeRemoteStore();
    engine = SyncEngine(
      remote: remote,
      users: InMemoryUserRepository(),
      rooms: InMemoryRoomRepository(
        newId: newRemoteId,
        newInviteCode: newRemoteInviteCode,
      ),
      competitions: InMemoryCompetitionRepository(newId: newRemoteId),
      activities: InMemoryActivityRepository(newId: newRemoteId),
      moderation: InMemoryModerationRepository(),
      debounce: Duration.zero,
    );
  });

  tearDown(() => engine.dispose());

  test('remote ids and invite codes are unique and unambiguous', () {
    final ids = {for (var i = 0; i < 500; i++) newRemoteId('room')};
    expect(ids, hasLength(500));
    expect(ids.first, startsWith('room-'));
    final code = newRemoteInviteCode();
    expect(code, matches(RegExp(r'^[A-HJ-NP-Z2-9]{6}$')));
  });

  test('room creation is optimistic and pushes room then owner', () async {
    final rooms = SyncedRoomRepository(engine);
    final room = rooms.createLocalRoom(
      name: 'Corrida Real',
      ownerUserId: 'u1',
      createdAt: DateTime(2026, 10, 30),
    );
    expect(rooms.getRoom(room.id)!.memberIds, ['u1']);
    await engine.flush();
    expect(remote.calls, ['room:${room.id}', 'member:${room.id}:u1']);
  });

  test('joining twice pushes membership once', () async {
    final rooms = SyncedRoomRepository(engine);
    final room = rooms.createLocalRoom(
      name: 'Corrida Real',
      ownerUserId: 'u1',
      createdAt: DateTime(2026, 10, 30),
    );
    expect(
      rooms.joinRoomByCode(room.inviteCode.toLowerCase(), 'u2'),
      isNotNull,
    );
    rooms.joinRoomByCode(room.inviteCode, 'u2');
    await engine.flush();
    expect(
      remote.calls.where((c) => c == 'member:${room.id}:u2'),
      hasLength(1),
    );
  });

  test('refresh replaces the cache with the remote snapshot', () async {
    var refreshed = 0;
    engine.onRefreshed = () => refreshed++;
    remote.snapshot = RemoteSnapshot(
      users: const [User(id: 'u1', displayName: 'Ana')],
      rooms: [
        Room(
          id: 'room-1',
          name: 'Sala',
          ownerUserId: 'u1',
          inviteCode: 'ABC234',
          memberIds: const ['u1'],
          createdAt: DateTime(2026, 10, 23),
        ),
      ],
    );
    await engine.refresh();
    expect(engine.users.getUser('u1')!.displayName, 'Ana');
    expect(engine.rooms.findByInviteCode('abc234')!.id, 'room-1');
    expect(refreshed, 1);
  });

  test('refresh waits for pending writes so local data is kept', () async {
    remote.gate = Completer<void>();
    final rooms = SyncedRoomRepository(engine);
    final room = rooms.createLocalRoom(
      name: 'Corrida Real',
      ownerUserId: 'u1',
      createdAt: DateTime(2026, 10, 30),
    );
    await engine.refresh(); // Deferred: a write is still in flight.
    expect(rooms.getRoom(room.id), isNotNull);
    expect(engine.hasPendingWrites, isTrue);
    remote.snapshot = RemoteSnapshot(rooms: [rooms.getRoom(room.id)!]);
    remote.gate!.complete();
    await engine.flush();
    await pumpEventQueue();
    expect(rooms.getRoom(room.id), isNotNull);
  });

  test('write failures are reported and trigger a reload', () async {
    final messages = <String>[];
    engine.messages.listen(messages.add);
    remote.failWrites = true;
    SyncedUserRepository(engine)
        .addUser(const User(id: 'u1', displayName: 'Ana'));
    await engine.flush();
    await pumpEventQueue();
    expect(messages.single, contains('Não foi possível salvar'));
    // The reload replaced the optimistic profile with the (empty) server copy.
    expect(engine.users.getUser('u1'), isNull);
  });

  test(
    'offline refresh is reported once until the connection returns',
    () async {
      final messages = <String>[];
      engine.messages.listen(messages.add);
      remote.failFetch = true;
      await engine.refresh();
      await engine.refresh();
      remote.failFetch = false;
      await engine.refresh();
      await pumpEventQueue();
      expect(messages, [
        'Sem conexão com o servidor. Tentando novamente…',
        'Conexão restabelecida.',
      ]);
    },
  );

  test('evidence is uploaded before the activity that references it', () async {
    final evidence = SyncedEvidenceRepository(engine, userId: 'u1');
    final activities = SyncedActivityRepository(engine);
    final ref = evidence.storeBytes(Uint8List.fromList([0xff, 0xd8, 0xff, 1]));
    expect(ref.kind, EvidenceKind.remote);
    expect(ref.id, matches(RegExp(r'^u1/evidence-[0-9a-f]{32}\.jpg$')));
    expect(evidence.getBytes(ref), isNotNull);
    final activity = activities.createLocalActivity(
      competitionId: 'c1',
      userId: 'u1',
      distanceKm: 5,
      durationSeconds: 1800,
      averagePaceSecondsPerKm: 360,
      evidenceRef: ref,
      score: 500,
      submittedAt: DateTime(2026, 10, 30),
    );
    await engine.flush();
    expect(remote.calls, ['upload:${ref.id}', 'activity:${activity.id}']);
  });

  test('realtime notifications schedule a refresh', () async {
    engine.start();
    remote.snapshot = const RemoteSnapshot(
      users: [User(id: 'u9', displayName: 'Nova')],
    );
    remote.onChange!();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(engine.users.getUser('u9'), isNotNull);
  });

  Activity submit(SyncedActivityRepository repo, EvidenceRef ref) =>
      repo.createLocalActivity(
        competitionId: 'c1',
        userId: 'u1',
        distanceKm: 5,
        durationSeconds: 1800,
        averagePaceSecondsPerKm: 360,
        evidenceRef: ref,
        score: 500,
        submittedAt: DateTime(2026, 10, 30),
      );

  test('activity is confirmed only after the server accepts it', () async {
    final evidence = SyncedEvidenceRepository(engine, userId: 'u1');
    final activities = SyncedActivityRepository(engine, evidence: evidence);
    final ref = evidence.storeBytes(Uint8List.fromList([0xff, 0xd8, 0xff]));
    final activity = submit(activities, ref);
    expect(await activities.whenSaved(activity.id), isTrue);
  });

  test(
    'a failed prefetch upload is retried silently by the activity',
    () async {
      final messages = <String>[];
      engine.messages.listen(messages.add);
      remote.failNext['upload'] = 1;
      final evidence = SyncedEvidenceRepository(engine, userId: 'u1');
      final activities = SyncedActivityRepository(engine, evidence: evidence);
      final ref = evidence.storeBytes(Uint8List.fromList([0xff, 0xd8, 0xff]));
      final activity = submit(activities, ref);
      expect(await activities.whenSaved(activity.id), isTrue);
      expect(remote.calls, [
        'upload:${ref.id}',
        'upload:${ref.id}',
        'activity:${activity.id}',
      ]);
      expect(messages, isEmpty);
    },
  );

  test('a failed activity is reported and removed by the reload', () async {
    final messages = <String>[];
    engine.messages.listen(messages.add);
    final evidence = SyncedEvidenceRepository(engine, userId: 'u1');
    final activities = SyncedActivityRepository(engine, evidence: evidence);
    final ref = evidence.storeBytes(Uint8List.fromList([0xff, 0xd8, 0xff]));
    remote.failNext['activity'] = 1;
    final activity = submit(activities, ref);
    expect(await activities.whenSaved(activity.id), isFalse);
    await pumpEventQueue();
    expect(messages.single, contains('Não foi possível salvar'));
    expect(activities.getActivity(activity.id), isNull);
  });

  test('server rule rejections are shown with their own message', () async {
    final messages = <String>[];
    engine.messages.listen(messages.add);
    remote.rejectWith = 'Esta denúncia não está aberta.';
    engine.moderation.putReport(
      ActivityReport(
        id: 'r1',
        activityId: 'a1',
        reporterUserId: 'u3',
        reason: ReportReason.other,
        status: ReportStatus.open,
        createdAt: DateTime(2026, 10, 30),
      ),
    );
    SyncedModerationRepository(engine).addVote(
      ReportVote(
        id: 'v1',
        reportId: 'r1',
        voterUserId: 'u2',
        vote: VoteType.invalid,
        createdAt: DateTime(2026, 10, 30),
      ),
    );
    await engine.flush();
    await pumpEventQueue();
    expect(messages.single, startsWith('Esta denúncia não está aberta.'));
  });

  test('moderation goes through server functions only', () async {
    engine.activities.createActivity(
      Activity(
        id: 'a1',
        competitionId: 'c1',
        userId: 'u1',
        distanceKm: 5,
        durationSeconds: 1800,
        averagePaceSecondsPerKm: 360,
        evidenceRef: const EvidenceRef(
          id: 'u1/e.jpg',
          kind: EvidenceKind.remote,
        ),
        score: 500,
        moderationStatus: ActivityModerationStatus.published,
        submittedAt: DateTime(2026, 10, 30),
      ),
    );
    final moderation = SyncedModerationRepository(engine);
    final activities = SyncedActivityRepository(engine);
    final report = ActivityReport(
      id: 'r1',
      activityId: 'a1',
      reporterUserId: 'u2',
      reason: ReportReason.other,
      status: ReportStatus.open,
      createdAt: DateTime(2026, 10, 30),
    );
    moderation.createReport(report);
    activities.updateModerationStatus(
      'a1',
      ActivityModerationStatus.underReview,
    );
    moderation.addVote(
      ReportVote(
        id: 'v1',
        reportId: 'r1',
        voterUserId: 'u3',
        vote: VoteType.invalid,
        createdAt: DateTime(2026, 10, 30),
      ),
    );
    moderation.resolveReport('r1', ReportStatus.upheld);
    activities.updateModerationStatus('a1', ActivityModerationStatus.rejected);
    await engine.flush();
    expect(remote.calls, ['report:r1', 'vote:v1']);
    expect(
      activities.getActivity('a1')!.moderationStatus,
      ActivityModerationStatus.rejected,
    );
  });

  test('joining a competition is optimistic and calls the server', () async {
    final competitions = SyncedCompetitionRepository(engine);
    competitions.createCompetition(
      Competition(
        id: 'c1',
        roomId: 'r1',
        name: 'Desafio',
        startsAt: DateTime(2026, 10, 30),
        endsAt: DateTime(2026, 11, 6),
        status: CompetitionStatus.scheduled,
        participantIds: const ['u1'],
      ),
    );
    competitions.joinCompetition('c1', 'u2');
    expect(competitions.getParticipantIds('c1'), ['u1', 'u2']);
    await engine.flush();
    expect(remote.calls, ['join:c1']);
  });
}
