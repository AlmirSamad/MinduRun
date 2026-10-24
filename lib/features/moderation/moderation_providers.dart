import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/bootstrap/providers.dart';
import '../../core/models/models.dart';
import '../../core/services/domain_services.dart';
import '../activities/activity_providers.dart';
import '../competitions/competition_providers.dart';
import '../session/session_providers.dart';

/// Revision only: reports and votes remain owned by the repository.
class ModerationController extends Notifier<int> {
  int _nextId = 1;
  @override
  int build() {
    final subscription = ref
        .watch(moderationRepositoryProvider)
        .changes
        .listen((_) => state++);
    ref.onDispose(subscription.cancel);
    return 0;
  }

  ActivityReport reportActivity(
    String activityId,
    ReportReason reason, {
    String? details,
  }) {
    final activity = ref.read(activityByIdProvider(activityId));
    final user = ref.read(currentUserProvider);
    if (activity == null || user == null) {
      throw StateError('Atividade ou sessão indisponível.');
    }
    final competition = ref.read(
      competitionByIdProvider(activity.competitionId),
    );
    final repo = ref.read(moderationRepositoryProvider);
    if (!ref
        .read(moderationServiceProvider)
        .canReport(
          activity: activity,
          reporterUserId: user.id,
          participantIds: competition?.participantIds ?? [],
          existingReports: repo.listActivityReports(activity.id),
        )) {
      throw StateError(
        'Você não pode denunciar esta atividade. Ela pode já estar em revisão, rejeitada ou ter sido denunciada por você.',
      );
    }
    final text = details?.trim();
    if ((text?.length ?? 0) > ModerationService.maxDetailsLength) {
      throw const FormatException('Use até 500 caracteres nos detalhes.');
    }
    final newId = ref.read(newIdProvider);
    String id;
    do {
      id = newId?.call('report') ?? 'report-local-${_nextId++}';
    } while (repo.getReport(id) != null);
    final report = ActivityReport(
      id: id,
      activityId: activity.id,
      reporterUserId: user.id,
      reason: reason,
      details: text == null || text.isEmpty ? null : text,
      status: ReportStatus.open,
      createdAt: ref.read(clockProvider)(),
    );
    repo.createReport(report);
    ref
        .read(activityRepositoryProvider)
        .updateModerationStatus(
          activity.id,
          ActivityModerationStatus.underReview,
        );
    return report;
  }

  void vote(String reportId, VoteType vote) {
    final report = ref.read(moderationRepositoryProvider).getReport(reportId);
    final user = ref.read(currentUserProvider);
    if (report == null || user == null) {
      throw StateError('Denúncia ou sessão indisponível.');
    }
    final activity = ref.read(activityByIdProvider(report.activityId));
    if (activity == null) throw StateError('Atividade indisponível.');
    final competition = ref.read(
      competitionByIdProvider(activity.competitionId),
    );
    final repo = ref.read(moderationRepositoryProvider);
    final service = ref.read(moderationServiceProvider);
    if (repo.listReportVotes(reportId).any((v) => v.voterUserId == user.id)) {
      throw StateError('Você já votou nesta denúncia.');
    }
    if (!service.canVote(
      activity: activity,
      report: report,
      voterUserId: user.id,
      participantIds: competition?.participantIds ?? [],
      votes: repo.listReportVotes(reportId),
    )) {
      throw StateError(
        'Voto não permitido: verifique sua elegibilidade, voto anterior e se a denúncia está aberta.',
      );
    }
    repo.addVote(
      ReportVote(
        id: 'vote-$reportId-${user.id}',
        reportId: reportId,
        voterUserId: user.id,
        vote: vote,
        createdAt: ref.read(clockProvider)(),
      ),
    );
    final outcome = service.evaluate(
      votes: repo.listReportVotes(reportId),
      eligibleVoterCount: service
          .eligibleVoters(
            activity: activity,
            participantIds: competition!.participantIds,
          )
          .length,
    );
    if (outcome != ModerationOutcome.pending) {
      final rejected = outcome == ModerationOutcome.reject;
      repo.resolveReport(
        reportId,
        rejected ? ReportStatus.upheld : ReportStatus.dismissed,
      );
      ref
          .read(activityRepositoryProvider)
          .updateModerationStatus(
            activity.id,
            rejected
                ? ActivityModerationStatus.rejected
                : ActivityModerationStatus.published,
          );
    }
  }
}

final moderationControllerProvider =
    NotifierProvider<ModerationController, int>(ModerationController.new);

final reportsForActivityProvider =
    Provider.family<List<ActivityReport>, String>((ref, id) {
      ref.watch(moderationControllerProvider);
      if (ref.watch(activityByIdProvider(id)) == null) return const [];
      return ref.watch(moderationRepositoryProvider).listActivityReports(id);
    });
final reportsForCompetitionProvider =
    Provider.family<List<ActivityReport>, String>((ref, id) {
      ref.watch(moderationControllerProvider);
      final ids = ref
          .watch(activitiesForCompetitionProvider(id))
          .map((a) => a.id)
          .toSet();
      return ref
          .watch(moderationRepositoryProvider)
          .listReports()
          .where((r) => ids.contains(r.activityId))
          .toList();
    });
final reportByIdProvider = Provider.family<ActivityReport?, String>((ref, id) {
  ref.watch(moderationControllerProvider);
  final report = ref.watch(moderationRepositoryProvider).getReport(id);
  if (report == null ||
      ref.watch(activityByIdProvider(report.activityId)) == null) {
    return null;
  }
  return report;
});
final votesForReportProvider = Provider.family<List<ReportVote>, String>((
  ref,
  id,
) {
  ref.watch(moderationControllerProvider);
  if (ref.watch(reportByIdProvider(id)) == null) return const [];
  return ref.watch(moderationRepositoryProvider).listReportVotes(id);
});
final canReportActivityProvider = Provider.family<bool, String>((ref, id) {
  final activity = ref.watch(activityByIdProvider(id));
  final user = ref.watch(currentUserProvider);
  if (activity == null || user == null) return false;
  return ref
      .watch(moderationServiceProvider)
      .canReport(
        activity: activity,
        reporterUserId: user.id,
        participantIds:
            ref
                .watch(competitionByIdProvider(activity.competitionId))
                ?.participantIds ??
            [],
        existingReports: ref.watch(reportsForActivityProvider(id)),
      );
});
final canVoteReportProvider = Provider.family<bool, String>((ref, id) {
  final report = ref.watch(reportByIdProvider(id));
  final user = ref.watch(currentUserProvider);
  if (report == null || user == null) return false;
  final activity = ref.watch(activityByIdProvider(report.activityId));
  if (activity == null) return false;
  return ref
      .watch(moderationServiceProvider)
      .canVote(
        activity: activity,
        report: report,
        voterUserId: user.id,
        participantIds:
            ref
                .watch(competitionByIdProvider(activity.competitionId))
                ?.participantIds ??
            [],
        votes: ref.watch(votesForReportProvider(id)),
      );
});
final minimumVotesForReportProvider = Provider.family<int, String>((ref, id) {
  final report = ref.watch(reportByIdProvider(id));
  if (report == null) return 0;
  final activity = ref.watch(activityByIdProvider(report.activityId));
  if (activity == null) return 0;
  final service = ref.watch(moderationServiceProvider);
  return service.minimumVotes(
    service
        .eligibleVoters(
          activity: activity,
          participantIds:
              ref
                  .watch(competitionByIdProvider(activity.competitionId))
                  ?.participantIds ??
              [],
        )
        .length,
  );
});
