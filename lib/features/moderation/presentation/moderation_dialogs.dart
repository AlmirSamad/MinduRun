import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_widgets.dart';
import '../../../core/models/models.dart';
import '../../../core/services/activity_input.dart';
import '../../../core/services/domain_services.dart';
import '../../activities/activity_providers.dart';
import '../../activities/presentation/evidence_image.dart';
import '../../session/session_providers.dart';
import '../moderation_providers.dart';

String reportReasonLabel(ReportReason reason) => switch (reason) {
  ReportReason.distanceMismatch => 'Distância diferente da evidência',
  ReportReason.durationMismatch => 'Duração diferente da evidência',
  ReportReason.paceMismatch => 'Ritmo diferente da evidência',
  ReportReason.invalidEvidence => 'Evidência inválida',
  ReportReason.duplicateActivity => 'Atividade duplicada',
  ReportReason.suspectedOtherPersonActivity =>
    'Possível atividade de outra pessoa',
  ReportReason.other => 'Outro motivo',
};

class ActivityModerationActions extends ConsumerWidget {
  const ActivityModerationActions({super.key, required this.activityId});
  final String activityId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(reportsForActivityProvider(activityId));
    return Wrap(
      spacing: 8,
      children: [
        if (ref.watch(canReportActivityProvider(activityId)))
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => ReportActivityDialog(activityId: activityId),
            ),
            icon: const Icon(Icons.flag_rounded, size: 18),
            label: const Text('Reportar'),
          ),
        if (reports.isNotEmpty)
          TextButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => ReportVotingDialog(reportId: reports.last.id),
            ),
            icon: const Icon(Icons.how_to_vote_rounded, size: 18),
            label: const Text('Ver votação'),
          ),
      ],
    );
  }
}

class ReportActivityDialog extends ConsumerStatefulWidget {
  const ReportActivityDialog({super.key, required this.activityId});
  final String activityId;
  @override
  ConsumerState<ReportActivityDialog> createState() =>
      _ReportActivityDialogState();
}

class _ReportActivityDialogState extends ConsumerState<ReportActivityDialog> {
  final _form = GlobalKey<FormState>();
  final _details = TextEditingController();
  ReportReason _reason = ReportReason.distanceMismatch;
  String? _error;
  bool _submitted = false;
  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Reportar atividade'),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'A atividade entrará em revisão pelos participantes elegíveis. Os pontos continuam contando até a decisão da votação.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ReportReason>(
                initialValue: _reason,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Motivo'),
                items: [
                  for (final reason in ReportReason.values)
                    DropdownMenuItem(
                      value: reason,
                      child: Text(reportReasonLabel(reason), maxLines: 2),
                    ),
                ],
                onChanged: (reason) {
                  if (reason != null) _reason = reason;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('report-details'),
                controller: _details,
                decoration: const InputDecoration(
                  labelText: 'Detalhes opcionais',
                ),
                minLines: 2,
                maxLines: 4,
                maxLength: ModerationService.maxDetailsLength,
                validator: (value) =>
                    (value?.trim().length ?? 0) >
                        ModerationService.maxDetailsLength
                    ? 'Use até 500 caracteres.'
                    : null,
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.ink,
        ),
        onPressed: () {
          if (_submitted) return;
          if (!_form.currentState!.validate()) return;
          try {
            _submitted = true;
            ref
                .read(moderationControllerProvider.notifier)
                .reportActivity(
                  widget.activityId,
                  _reason,
                  details: _details.text,
                );
            Navigator.of(context).pop();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Denúncia enviada.')));
          } on StateError catch (error) {
            setState(() {
              _submitted = false;
              _error = error.message;
            });
          } on FormatException catch (error) {
            setState(() {
              _submitted = false;
              _error = error.message;
            });
          }
        },
        child: const Text('Enviar denúncia'),
      ),
    ],
  );
}

class ReportVotingDialog extends ConsumerStatefulWidget {
  const ReportVotingDialog({super.key, required this.reportId});
  final String reportId;
  @override
  ConsumerState<ReportVotingDialog> createState() => _ReportVotingDialogState();
}

class _ReportVotingDialogState extends ConsumerState<ReportVotingDialog> {
  String? _error;
  void _vote(VoteType vote) {
    try {
      ref
          .read(moderationControllerProvider.notifier)
          .vote(widget.reportId, vote);
    } on StateError catch (error) {
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(reportByIdProvider(widget.reportId));
    final activity = report == null
        ? null
        : ref.watch(activityByIdProvider(report.activityId));
    final votes = ref.watch(votesForReportProvider(widget.reportId));
    final user = ref.watch(currentUserProvider);
    final ownVotes = votes.where((v) => v.voterUserId == user?.id);
    final authorName = activity == null
        ? ''
        : ref
                  .watch(userRepositoryProvider)
                  .getUser(activity.userId)
                  ?.displayName ??
              activity.userId;
    return AlertDialog(
      title: const Text('Votação da atividade'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: activity == null || report == null
              ? const Text('Denúncia indisponível nesta sessão.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        UserAvatar(name: authorName),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authorName,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                '${activity.score} pontos originais',
                                style: AppFonts.numbers(
                                  size: 16,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        StatTile(
                          icon: Icons.route_rounded,
                          value: ActivityInput.formatDistance(
                            activity.distanceKm,
                          ),
                          caption: 'Distância',
                        ),
                        const SizedBox(width: 8),
                        StatTile(
                          icon: Icons.timer_rounded,
                          value: ActivityInput.formatDuration(
                            activity.durationSeconds,
                          ),
                          caption: 'Duração',
                        ),
                        const SizedBox(width: 8),
                        StatTile(
                          icon: Icons.speed_rounded,
                          value: ActivityInput.formatPace(
                            activity.averagePaceSecondsPerKm,
                          ),
                          caption: 'Ritmo',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                          AppTheme.controlRadius,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.flag_rounded,
                                size: 16,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Motivo: ${reportReasonLabel(report.reason)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (report.details != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                report.details!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 240,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(
                          AppTheme.controlRadius,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: EvidenceImage(evidence: activity.evidenceRef),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          showActivityEvidence(context, activity.evidenceRef),
                      icon: const Icon(Icons.image_rounded, size: 18),
                      label: const Text('Ver evidência'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          report.status == ReportStatus.open
                              ? Icons.how_to_vote_rounded
                              : report.status == ReportStatus.upheld
                              ? Icons.cancel_rounded
                              : Icons.check_circle_rounded,
                          size: 18,
                          color: report.status == ReportStatus.open
                              ? AppColors.warning
                              : report.status == ReportStatus.upheld
                              ? AppColors.error
                              : AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: report.status == ReportStatus.open
                              ? Text(
                                  '${votes.length} de ${ref.watch(minimumVotesForReportProvider(report.id))} votos necessários',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : Text(
                                  report.status == ReportStatus.upheld
                                      ? 'Atividade invalidada pela votação.'
                                      : 'A atividade foi mantida.',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    if (ownVotes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Seu voto foi registrado.'),
                      Text(
                        ownVotes.first.vote == VoteType.invalid
                            ? 'Seu voto: a evidência é inconsistente.'
                            : 'Seu voto: a atividade parece válida.',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                    if (user?.id == activity.userId)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'O autor pode acompanhar a votação, mas não pode votar.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    if (ref.watch(canVoteReportProvider(report.id))) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => _vote(VoteType.valid),
                        icon: const Icon(Icons.thumb_up_rounded),
                        label: const Text('A atividade parece válida'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: AppColors.ink,
                        ),
                        onPressed: () => _vote(VoteType.invalid),
                        icon: const Icon(Icons.thumb_down_rounded),
                        label: const Text('A evidência é inconsistente'),
                      ),
                    ],
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                  ],
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
