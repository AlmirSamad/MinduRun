import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/providers.dart';
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
          TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => ReportActivityDialog(activityId: activityId),
            ),
            child: const Text('Reportar'),
          ),
        if (reports.isNotEmpty)
          TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => ReportVotingDialog(reportId: reports.last.id),
            ),
            child: const Text('Ver votação'),
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
                    Text(
                      ref
                              .watch(userRepositoryProvider)
                              .getUser(activity.userId)
                              ?.displayName ??
                          activity.userId,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(ActivityInput.formatDistance(activity.distanceKm)),
                    Text(
                      'Duração: ${ActivityInput.formatDuration(activity.durationSeconds)}',
                    ),
                    Text(
                      'Ritmo: ${ActivityInput.formatPace(activity.averagePaceSecondsPerKm)}',
                    ),
                    Text('${activity.score} pontos originais'),
                    const SizedBox(height: 12),
                    Text('Motivo: ${reportReasonLabel(report.reason)}'),
                    if (report.details != null) Text(report.details!),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 240,
                      child: EvidenceImage(evidence: activity.evidenceRef),
                    ),
                    TextButton(
                      onPressed: () =>
                          showActivityEvidence(context, activity.evidenceRef),
                      child: const Text('Ver evidência'),
                    ),
                    const SizedBox(height: 12),
                    if (report.status == ReportStatus.open)
                      Text(
                        '${votes.length} de ${ref.watch(minimumVotesForReportProvider(report.id))} votos necessários',
                      )
                    else
                      Text(
                        report.status == ReportStatus.upheld
                            ? 'Atividade invalidada pela votação.'
                            : 'A atividade foi mantida.',
                      ),
                    if (ownVotes.isNotEmpty) ...[
                      const Text('Seu voto foi registrado.'),
                      Text(
                        ownVotes.first.vote == VoteType.invalid
                            ? 'Seu voto: a evidência é inconsistente.'
                            : 'Seu voto: a atividade parece válida.',
                      ),
                    ],
                    if (user?.id == activity.userId)
                      const Text(
                        'O autor pode acompanhar a votação, mas não pode votar.',
                      ),
                    if (ref.watch(canVoteReportProvider(report.id))) ...[
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => _vote(VoteType.invalid),
                        child: const Text('A evidência é inconsistente'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => _vote(VoteType.valid),
                        child: const Text('A atividade parece válida'),
                      ),
                    ],
                    if (_error != null)
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
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
