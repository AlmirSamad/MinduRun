import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/bootstrap/providers.dart';
import '../../core/models/models.dart';
import '../../core/services/activity_input.dart';
import '../competitions/competition_providers.dart';
import '../session/session_providers.dart';
import 'evidence_picker.dart';

typedef ActivityPreview = ({
  double distanceKm,
  int durationSeconds,
  int averagePaceSecondsPerKm,
  int score,
});

class ActivitiesController extends Notifier<List<Activity>> {
  @override
  List<Activity> build() {
    final repository = ref.watch(activityRepositoryProvider);
    final subscription = repository.changes.listen((_) {
      state = repository.listActivities();
    });
    ref.onDispose(subscription.cancel);
    return repository.listActivities();
  }

  /// Decode before accepting evidence, so corrupt files cannot be published.
  Future<EvidenceRef?> selectEvidence() async {
    final bytes = await ref.read(evidencePickerProvider)();
    if (bytes == null) return null;
    if (bytes.isEmpty || bytes.length > maxEvidenceBytes) {
      throw const FormatException('Escolha uma imagem válida de até 10 MB.');
    }
    if (!isSupportedEvidenceImage(bytes)) {
      throw const FormatException(
        'Não foi possível usar esta imagem. Escolha uma imagem PNG, JPEG ou WebP válida.',
      );
    }
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      try {
        final frame = await codec.getNextFrame();
        frame.image.dispose();
      } finally {
        codec.dispose();
      }
    } catch (_) {
      throw const FormatException(
        'Não foi possível usar esta imagem. Escolha uma imagem PNG, JPEG ou WebP válida.',
      );
    }
    return ref.read(evidenceRepositoryProvider).storeBytes(bytes);
  }

  ActivityPreview preview({
    required String competitionId,
    required String distance,
    required String duration,
    required String pace,
    EvidenceRef? evidence,
  }) {
    final user = ref.read(currentUserProvider);
    final competition = ref.read(competitionByIdProvider(competitionId));
    final service = ref.read(activitySubmissionServiceProvider);
    final authorization = service.authorizationError(
      competition,
      user?.id,
      ref.read(clockProvider)(),
    );
    if (authorization != null) throw StateError(authorization);
    if (evidence == null ||
        !ref.read(evidenceRepositoryProvider).exists(evidence)) {
      throw const FormatException('Selecione uma imagem de evidência.');
    }
    final distanceKm = ActivityInput.parseDistance(distance);
    final durationSeconds = ActivityInput.parseDuration(duration);
    final paceSeconds = ActivityInput.parsePace(pace);
    if (distanceKm == null) {
      throw FormatException(ActivityInput.validateDistance(distance)!);
    }
    if (durationSeconds == null) {
      throw FormatException(ActivityInput.validateDuration(duration)!);
    }
    if (paceSeconds == null) {
      throw FormatException(ActivityInput.validatePace(pace)!);
    }
    final error = service.metricsError(
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      averagePaceSecondsPerKm: paceSeconds,
    );
    if (error != null) throw FormatException(error);
    return (
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      averagePaceSecondsPerKm: paceSeconds,
      score: ref.read(scoringServiceProvider).calculateScore(distanceKm),
    );
  }

  Activity submitActivity({
    required String competitionId,
    required String distance,
    required String duration,
    required String pace,
    EvidenceRef? evidence,
  }) {
    // Revalidate on publish: a previously valid preview is not authorization.
    final values = preview(
      competitionId: competitionId,
      distance: distance,
      duration: duration,
      pace: pace,
      evidence: evidence,
    );
    final repo = ref.read(activityRepositoryProvider);
    final activity = repo.createLocalActivity(
      competitionId: competitionId,
      userId: ref.read(currentUserProvider)!.id,
      distanceKm: values.distanceKm,
      durationSeconds: values.durationSeconds,
      averagePaceSecondsPerKm: values.averagePaceSecondsPerKm,
      evidenceRef: evidence!,
      score: values.score,
      submittedAt: ref.read(clockProvider)(),
    );
    return activity;
  }
}

final activitiesControllerProvider =
    NotifierProvider<ActivitiesController, List<Activity>>(
      ActivitiesController.new,
    );

final activitiesForCompetitionProvider =
    Provider.family<List<Activity>, String>((ref, id) {
      ref.watch(activitiesControllerProvider);
      if (ref.watch(competitionByIdProvider(id)) == null) return const [];
      return ref
          .watch(activityRepositoryProvider)
          .listCompetitionActivities(id);
    });

final activityByIdProvider = Provider.family<Activity?, String>((ref, id) {
  ref.watch(activitiesControllerProvider);
  final activity = ref.watch(activityRepositoryProvider).getActivity(id);
  if (activity == null ||
      ref.watch(competitionByIdProvider(activity.competitionId)) == null) {
    return null;
  }
  return activity;
});

/// Preserve the original seed demo/ranking dependency, now reactive to submits.
final activeCompetitionActivitiesProvider = Provider<List<Activity>>((ref) {
  final competition = ref.watch(activeCompetitionProvider);
  if (competition == null) return const [];
  return ref.watch(activitiesForCompetitionProvider(competition.id));
});
