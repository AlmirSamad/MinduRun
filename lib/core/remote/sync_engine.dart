import 'dart:async';

import '../repositories/in_memory_repositories.dart';
import 'remote_store.dart';

/// Keeps the in-memory repositories (the local cache) in sync with the
/// remote store.
///
/// Writes are applied to the cache first (so the UI stays synchronous) and
/// pushed in order through a single queue. The cache is rebuilt from a full
/// remote snapshot on realtime notifications, on a timer and on demand, but
/// only while no local write is pending, so optimistic data is never lost.
class SyncEngine {
  SyncEngine({
    required this.remote,
    required this.users,
    required this.rooms,
    required this.competitions,
    required this.activities,
    required this.moderation,
    this.pollInterval = const Duration(seconds: 20),
    this.debounce = const Duration(milliseconds: 400),
    this.jobTimeout = const Duration(seconds: 45),
  });

  final RemoteStore remote;
  final InMemoryUserRepository users;
  final InMemoryRoomRepository rooms;
  final InMemoryCompetitionRepository competitions;
  final InMemoryActivityRepository activities;
  final InMemoryModerationRepository moderation;
  final Duration pollInterval;
  final Duration debounce;

  /// A write that takes longer is treated as failed (bad mobile signal).
  final Duration jobTimeout;

  /// Called after the cache was rebuilt from the remote store.
  void Function()? onRefreshed;

  /// Server time minus phone time, updated on every refresh.
  Duration clockOffset = Duration.zero;

  /// Phone time corrected to the server clock.
  DateTime now() => DateTime.now().add(clockOffset);

  final _messages = StreamController<String>.broadcast();
  Future<void> _queue = Future.value();
  int _pending = 0;
  bool _refreshing = false;
  bool _refreshWanted = false;
  bool _offline = false;
  Timer? _debounceTimer;
  Timer? _pollTimer;
  void Function()? _stopWatching;

  /// User-facing sync problems (shown as snack bars).
  Stream<String> get messages => _messages.stream;

  /// True while local writes are waiting to reach the remote store.
  bool get hasPendingWrites => _pending > 0;

  /// Pushes a local write. Jobs run one at a time, in call order. The
  /// returned future completes with whether the server accepted it (it never
  /// throws). A failed job reports a message and reloads the cache from the
  /// server, unless [silent] (used for best-effort prefetch uploads).
  Future<bool> enqueue(Future<void> Function() job, {bool silent = false}) {
    _pending++;
    final result = Completer<bool>();
    _queue = _queue.then((_) async {
      try {
        await job().timeout(jobTimeout);
        result.complete(true);
      } catch (error) {
        result.complete(false);
        if (!silent) {
          _messages.add(
            error is RemoteRejected
                ? '${error.message} Os dados foram recarregados.'
                : 'Não foi possível salvar no servidor. Verifique a internet; '
                      'os dados serão recarregados.',
          );
          _refreshWanted = true;
        }
      } finally {
        _pending--;
        if (_pending == 0 && _refreshWanted) unawaited(refresh());
      }
    });
    return result.future;
  }

  /// Completes when every queued write finished (successfully or not).
  Future<void> flush() => _queue;

  /// Rebuilds the cache from the remote store. With [throwOnError], network
  /// failures propagate (used at startup); otherwise they are reported once.
  Future<void> refresh({bool throwOnError = false}) async {
    if (_refreshing || _pending > 0) {
      _refreshWanted = true;
      return;
    }
    _refreshing = true;
    _refreshWanted = false;
    try {
      final started = DateTime.now();
      final snapshot = await remote.fetchAll();
      final serverTime = snapshot.serverTime;
      if (serverTime != null) {
        // Assume the server read happened halfway through the round trip.
        final midpoint = started.add(DateTime.now().difference(started) ~/ 2);
        clockOffset = serverTime.difference(midpoint);
      }
      if (_pending > 0) {
        // A local write started meanwhile; this snapshot may predate it.
        _refreshWanted = true;
      } else {
        _apply(snapshot);
        if (_offline) _messages.add('Conexão restabelecida.');
        _offline = false;
        onRefreshed?.call();
      }
    } catch (_) {
      if (throwOnError) rethrow;
      if (!_offline) {
        _messages.add('Sem conexão com o servidor. Tentando novamente…');
      }
      _offline = true;
    } finally {
      _refreshing = false;
    }
    if (_refreshWanted && _pending == 0) unawaited(refresh());
  }

  /// Debounced refresh for bursts of realtime notifications.
  void refreshSoon() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () => unawaited(refresh()));
  }

  /// Starts realtime watching and periodic polling.
  void start() {
    _stopWatching ??= remote.watch(refreshSoon);
    _pollTimer ??= Timer.periodic(pollInterval, (_) => unawaited(refresh()));
  }

  void dispose() {
    _stopWatching?.call();
    _stopWatching = null;
    _debounceTimer?.cancel();
    _pollTimer?.cancel();
    unawaited(_messages.close());
  }

  void _apply(RemoteSnapshot snapshot) {
    users.clear();
    snapshot.users.forEach(users.addUser);
    rooms.clear();
    snapshot.rooms.forEach(rooms.createRoom);
    competitions.clear();
    snapshot.competitions.forEach(competitions.createCompetition);
    activities.clear();
    snapshot.activities.forEach(activities.createActivity);
    moderation.clear();
    snapshot.reports.forEach(moderation.putReport);
    snapshot.votes.forEach(moderation.putVote);
  }
}
