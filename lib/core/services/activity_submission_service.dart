import '../models/models.dart';
import 'domain_services.dart';

/// Application-independent submission policy. No image parsing or OCR.
class ActivitySubmissionService {
  const ActivitySubmissionService({
    this.competitionState = const CompetitionStateService(),
    this.pace = const PaceValidationService(),
  });
  final CompetitionStateService competitionState;
  final PaceValidationService pace;

  String? authorizationError(
    Competition? competition,
    String? userId,
    DateTime now,
  ) {
    if (userId == null) {
      return 'Selecione um usuário para registrar uma atividade.';
    }
    if (competition == null) return 'Competição não encontrada.';
    if (!competition.participantIds.contains(userId)) {
      return 'Você não é participante desta competição.';
    }
    if (!competitionState.acceptsSubmissions(competition, now)) {
      return 'Somente competições ativas permitem registrar atividades.';
    }
    return null;
  }

  /// The author may delete an activity (e.g. a typo) while the competition is
  /// ACTIVE, the activity is PUBLISHED and it never received a report, so a
  /// deletion can neither dodge moderation nor change a closed result.
  bool canDelete({
    required Activity activity,
    required String? userId,
    required Competition? competition,
    required List<ActivityReport> reports,
    required DateTime now,
  }) =>
      userId != null &&
      activity.userId == userId &&
      activity.moderationStatus == ActivityModerationStatus.published &&
      competition != null &&
      competition.id == activity.competitionId &&
      competitionState.acceptsSubmissions(competition, now) &&
      !reports.any((r) => r.activityId == activity.id);

  /// The same screenshot (by fingerprint) may back only one activity per
  /// competition, whatever that activity's moderation status.
  String? duplicateEvidenceError({
    required String? evidenceHash,
    required String competitionId,
    required List<Activity> existing,
  }) =>
      evidenceHash != null &&
          existing.any(
            (a) =>
                a.competitionId == competitionId &&
                a.evidenceHash == evidenceHash,
          )
      ? 'Este print já foi usado em outra atividade desta competição.'
      : null;

  String? metricsError({
    required double distanceKm,
    required int durationSeconds,
    required int averagePaceSecondsPerKm,
  }) => switch (pace.validate(
    distanceKm: distanceKm,
    durationSeconds: durationSeconds,
    averagePaceSecondsPerKm: averagePaceSecondsPerKm,
  )) {
    PaceValidationResult.valid => null,
    PaceValidationResult.invalidDistance =>
      'Informe uma distância válida maior que zero.',
    PaceValidationResult.invalidDuration =>
      'Informe uma duração válida maior que zero.',
    PaceValidationResult.invalidPace =>
      'Informe um ritmo válido maior que zero.',
    PaceValidationResult.inconsistentPace => 'Os dados informados não são consistentes. Confira a distância, duração e ritmo médio.',
  };
}
