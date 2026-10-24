import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../core/remote/remote_ids.dart';
import '../../core/remote/supabase_remote_store.dart';
import '../../core/remote/sync_engine.dart';
import '../../core/remote/synced_repositories.dart';
import '../../core/repositories/in_memory_repositories.dart';
import '../../features/activities/evidence_image_picker.dart';
import '../../features/activities/evidence_picker.dart';
import '../../features/session/session_providers.dart';
import '../app.dart';
import '../theme/app_theme.dart';
import 'app_config.dart';
import 'providers.dart';

/// Connects to Supabase (anonymous sign-in, initial download) before showing
/// the app. Shows a retry screen when the phone is offline.
class SyncedStartup extends StatefulWidget {
  const SyncedStartup({super.key});

  @override
  State<SyncedStartup> createState() => _SyncedStartupState();
}

class _SyncedStartupState extends State<SyncedStartup> {
  static bool _supabaseReady = false;

  ProviderContainer? _container;
  SyncEngine? _engine;
  AppLifecycleListener? _lifecycle;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    _engine?.dispose();
    _container?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _failed = false);
    try {
      if (!_supabaseReady) {
        await Supabase.initialize(
          url: AppConfig.supabaseUrl,
          publishableKey: AppConfig.supabaseKey,
        );
        _supabaseReady = true;
      }
      final client = Supabase.instance.client;
      if (client.auth.currentUser == null) {
        await client.auth.signInAnonymously();
      }
      final userId = client.auth.currentUser!.id;
      final remote = SupabaseRemoteStore(client);
      final engine = SyncEngine(
        remote: remote,
        users: InMemoryUserRepository(),
        rooms: InMemoryRoomRepository(
          newId: newRemoteId,
          newInviteCode: newRemoteInviteCode,
        ),
        competitions: InMemoryCompetitionRepository(newId: newRemoteId),
        activities: InMemoryActivityRepository(newId: newRemoteId),
        moderation: InMemoryModerationRepository(),
      );
      await engine.refresh(throwOnError: true);
      final evidence = SyncedEvidenceRepository(engine, userId: userId);
      final container = ProviderContainer(
        overrides: [
          appModeProvider.overrideWithValue(AppMode.synced),
          clockProvider.overrideWithValue(engine.now),
          remoteUserIdProvider.overrideWithValue(userId),
          newIdProvider.overrideWithValue(newRemoteId),
          evidenceUrlProvider.overrideWithValue(remote.evidenceUrl),
          syncMessagesProvider.overrideWithValue(engine.messages),
          userRepositoryProvider.overrideWithValue(
            SyncedUserRepository(engine),
          ),
          roomRepositoryProvider.overrideWithValue(
            SyncedRoomRepository(engine),
          ),
          competitionRepositoryProvider.overrideWithValue(
            SyncedCompetitionRepository(engine),
          ),
          activityRepositoryProvider.overrideWithValue(
            SyncedActivityRepository(engine, evidence: evidence),
          ),
          moderationRepositoryProvider.overrideWithValue(
            SyncedModerationRepository(engine),
          ),
          evidenceRepositoryProvider.overrideWithValue(evidence),
          evidencePickerProvider.overrideWithValue(pickCompressedImageBytes),
        ],
      );
      engine.onRefreshed = () =>
          container.read(syncRevisionProvider.notifier).bump();
      engine.start();
      _lifecycle = AppLifecycleListener(onResume: engine.refreshSoon);
      final me = engine.users.getUser(userId);
      if (me != null) {
        container.read(sessionControllerProvider.notifier).selectUser(me);
      }
      if (!mounted) return;
      setState(() {
        _engine = engine;
        _container = container;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final container = _container;
    if (container != null) {
      return UncontrolledProviderScope(
        container: container,
        child: const MinduRunApp(),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _failed
                      ? Icons.wifi_off_rounded
                      : Icons.directions_run_rounded,
                  size: 56,
                  color: AppTheme.seed,
                ),
                const SizedBox(height: 16),
                Text(
                  _failed
                      ? 'Não foi possível conectar ao servidor.\nVerifique a internet e tente novamente.'
                      : 'Conectando…',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_failed)
                  FilledButton(
                    onPressed: _start,
                    child: const Text('Tentar novamente'),
                  )
                else
                  const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
