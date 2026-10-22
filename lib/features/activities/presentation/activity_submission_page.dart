import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/router/app_router.dart';
import '../../../core/models/models.dart';
import '../../../core/services/activity_input.dart';
import '../../competitions/competition_providers.dart';
import '../../session/session_providers.dart';
import '../activity_providers.dart';
import 'evidence_image.dart';

class ActivitySubmissionPage extends ConsumerStatefulWidget {
  const ActivitySubmissionPage({super.key, required this.competitionId});
  final String competitionId;
  @override
  ConsumerState<ActivitySubmissionPage> createState() =>
      _ActivitySubmissionPageState();
}

class _ActivitySubmissionPageState
    extends ConsumerState<ActivitySubmissionPage> {
  final _form = GlobalKey<FormState>();
  final _distance = TextEditingController();
  final _duration = TextEditingController();
  final _pace = TextEditingController();
  EvidenceRef? _evidence;
  ActivityPreview? _preview;
  String? _error;
  bool _picking = false;
  bool _published = false;

  @override
  void dispose() {
    _distance.dispose();
    _duration.dispose();
    _pace.dispose();
    super.dispose();
  }

  void _changed() => setState(() {
    _preview = null;
    _error = null;
  });

  Future<void> _pickEvidence() async {
    if (_picking || _published) return;
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final evidence = await ref
          .read(activitiesControllerProvider.notifier)
          .selectEvidence();
      if (!mounted) return;
      if (evidence != null) {
        setState(() {
          _evidence = evidence;
          _preview = null;
        });
      }
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Não foi possível selecionar a imagem. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _validate() {
    final fieldsValid = _form.currentState!.validate();
    if (_evidence == null) {
      setState(() => _error = 'Selecione uma imagem de evidência.');
      return;
    }
    if (!fieldsValid) return;
    try {
      final preview = ref
          .read(activitiesControllerProvider.notifier)
          .preview(
            competitionId: widget.competitionId,
            distance: _distance.text,
            duration: _duration.text,
            pace: _pace.text,
            evidence: _evidence,
          );
      setState(() {
        _preview = preview;
        _error = null;
      });
    } on FormatException catch (error) {
      setState(() {
        _preview = null;
        _error = error.message;
      });
    } on StateError catch (error) {
      setState(() {
        _preview = null;
        _error = error.message;
      });
    }
  }

  void _publish() {
    if (_published || _picking || _preview == null) return;
    setState(() => _published = true);
    try {
      ref
          .read(activitiesControllerProvider.notifier)
          .submitActivity(
            competitionId: widget.competitionId,
            distance: _distance.text,
            duration: _duration.text,
            pace: _pace.text,
            evidence: _evidence,
          );
      // Replacing this page also works when the form was opened by a direct URL.
      context.go(AppRoutes.competition(widget.competitionId));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Atividade publicada.')));
    } on FormatException catch (error) {
      setState(() {
        _published = false;
        _preview = null;
        _error = error.message;
      });
    } on StateError catch (error) {
      setState(() {
        _published = false;
        _preview = null;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final competition = ref.watch(
      competitionByIdProvider(widget.competitionId),
    );
    final user = ref.watch(currentUserProvider);
    final authorization = ref
        .watch(activitySubmissionServiceProvider)
        .authorizationError(competition, user?.id, ref.watch(clockProvider)());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar atividade'),
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.go(AppRoutes.competition(widget.competitionId)),
        ),
      ),
      body: authorization != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(authorization),
              ),
            )
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    competition!.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Registre uma corrida feita em outro aplicativo. Selecione a screenshot e digite os dados manualmente.',
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _picking || _published ? null : _pickEvidence,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(
                      _picking
                          ? 'Selecionando imagem…'
                          : 'Selecionar screenshot',
                    ),
                  ),
                  if (_evidence != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: EvidenceImage(evidence: _evidence!),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('activity-distance'),
                    controller: _distance,
                    decoration: const InputDecoration(
                      labelText: 'Distância (km)',
                      hintText: '5,23',
                      errorMaxLines: 3,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: ActivityInput.validateDistance,
                    onChanged: (_) => _changed(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('activity-duration'),
                    controller: _duration,
                    decoration: const InputDecoration(
                      labelText: 'Duração (MM:SS ou HH:MM:SS)',
                      hintText: '31:45',
                      errorMaxLines: 3,
                    ),
                    keyboardType: TextInputType.datetime,
                    validator: ActivityInput.validateDuration,
                    onChanged: (_) => _changed(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('activity-pace'),
                    controller: _pace,
                    decoration: const InputDecoration(
                      labelText: 'Ritmo médio (MM:SS/km)',
                      hintText: '06:04',
                      errorMaxLines: 3,
                    ),
                    keyboardType: TextInputType.datetime,
                    validator: ActivityInput.validatePace,
                    onChanged: (_) => _changed(),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  OutlinedButton(
                    onPressed: _picking || _published ? null : _validate,
                    child: const Text('Validar e ver pontuação'),
                  ),
                  if (_preview case final preview?)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Prévia da atividade'),
                            Text(
                              ActivityInput.formatDistance(preview.distanceKm),
                            ),
                            Text(
                              'Duração: ${ActivityInput.formatDuration(preview.durationSeconds)}',
                            ),
                            Text(
                              'Ritmo: ${ActivityInput.formatPace(preview.averagePaceSecondsPerKm)}',
                            ),
                            Text(
                              '${preview.score} pontos',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _preview == null || _picking || _published
                        ? null
                        : _publish,
                    child: const Text('Publicar atividade'),
                  ),
                ],
              ),
            ),
    );
  }
}
