import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../models/models.dart';
import 'remote_store.dart';

/// [RemoteStore] backed by `supabase/schema.sql` and
/// `supabase/migrations/002_join_and_server_moderation.sql`.
class SupabaseRemoteStore implements RemoteStore {
  SupabaseRemoteStore(this._client);

  static const bucket = 'evidence';

  final SupabaseClient _client;

  @override
  Future<RemoteSnapshot> fetchAll() async {
    final results = await Future.wait([
      _client.from('profiles').select(),
      _client.from('rooms').select(),
      _client.from('room_members').select().order('joined_at'),
      _client.from('competitions').select(),
      _client.from('activities').select(),
      _client.from('reports').select(),
      _client.from('votes').select(),
    ]);
    return RemoteSnapshot(
      users: results[0].map(RemoteRows.user).toList(),
      rooms: RemoteRows.rooms(results[1], results[2]),
      competitions: results[3].map(RemoteRows.competition).toList(),
      activities: results[4].map(RemoteRows.activity).toList(),
      reports: results[5].map(RemoteRows.report).toList(),
      votes: results[6].map(RemoteRows.vote).toList(),
    );
  }

  @override
  Future<void> upsertProfile(User user) =>
      _guard(() => _client.from('profiles').upsert(RemoteRows.userRow(user)));

  @override
  Future<void> insertRoom(Room room) =>
      _guard(() => _client.from('rooms').insert(RemoteRows.roomRow(room)));

  @override
  Future<void> insertMember(String roomId, String userId) => _guard(
    () => _client.from('room_members').insert({
      'room_id': roomId,
      'user_id': userId,
    }),
  );

  @override
  Future<void> insertCompetition(Competition competition) => _guard(
    () => _client
        .from('competitions')
        .insert(RemoteRows.competitionRow(competition)),
  );

  @override
  Future<void> joinCompetition(String competitionId) => _guard(
    () => _client.rpc(
      'join_competition',
      params: {'p_competition_id': competitionId},
    ),
  );

  @override
  Future<void> insertActivity(Activity activity) => _guard(
    () => _client.from('activities').insert(RemoteRows.activityRow(activity)),
  );

  @override
  Future<void> createReport(ActivityReport report) => _guard(
    () => _client.rpc(
      'create_report',
      params: {
        'p_id': report.id,
        'p_activity_id': report.activityId,
        'p_reason': report.reason.name,
        'p_details': report.details,
      },
    ),
  );

  @override
  Future<void> castVote(ReportVote vote) => _guard(
    () => _client.rpc(
      'cast_vote',
      params: {
        'p_id': vote.id,
        'p_report_id': vote.reportId,
        'p_vote': vote.vote.name,
      },
    ),
  );

  @override
  Future<void> uploadEvidence(String path, Uint8List bytes) => _guard(
    () => _client.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: evidenceContentType(bytes),
            upsert: true,
          ),
        ),
  );

  @override
  String evidenceUrl(String path) =>
      _client.storage.from(bucket).getPublicUrl(path);

  @override
  void Function() watch(void Function() onChange) {
    final channel = _client
        .channel('mindurun-db')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          callback: (_) => onChange(),
        )
        .subscribe();
    return () => _client.removeChannel(channel);
  }

  /// Turns rule violations raised by the database into [RemoteRejected];
  /// network failures keep their original type.
  static Future<void> _guard(Future<Object?> Function() call) async {
    try {
      await call();
    } on PostgrestException catch (error) {
      // P0001: `raise exception` in our functions (Portuguese message).
      if (error.code == 'P0001') throw RemoteRejected(error.message);
      if (error.code == '42501') {
        throw const RemoteRejected(
          'O servidor recusou a operação (sem permissão ou fora do prazo).',
        );
      }
      rethrow;
    }
  }
}

/// MIME type from the image signature (picker output is JPEG or PNG).
String evidenceContentType(Uint8List bytes) {
  if (bytes.length > 3 && bytes[0] == 0x89 && bytes[1] == 0x50) {
    return 'image/png';
  }
  if (bytes.length > 11 && bytes[8] == 0x57 && bytes[9] == 0x45) {
    return 'image/webp';
  }
  return 'image/jpeg';
}
