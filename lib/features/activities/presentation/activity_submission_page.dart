import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_widgets.dart';
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

  /// True once the user typed a pace: then it is never overwritten.
  bool _paceTyped = false;

  void _changed() => setState(() {
    _preview = null;
    _error = null;
  });

  /// Fills the pace from distance and duration while the user has not typed
  /// one (clearing the field resumes the automatic value).
  void _metricsChanged() {
    if (!_paceTyped) {
      _pace.text =
          ActivityInput.suggestPace(_distance.text, _duration.text) ?? '';
    }
    _changed();
  }

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

  /// Confirms only after the activity is stored (server-accepted in synced
  /// mode); on failure the form stays filled so the user can retry.
  Future<void> _publish() async {
    if (_published || _picking || _preview == null) return;
    setState(() => _published = true);
    try {
      final activity = ref
          .read(activitiesControllerProvider.notifier)
          .submitActivity(
            competitionId: widget.competitionId,
            distance: _distance.text,
            duration: _duration.text,
            pace: _pace.text,
            evidence: _evidence,
          );
      final saved = await ref
          .read(activityRepositoryProvider)
          .whenSaved(activity.id);
      if (!mounted) return;
      if (!saved) {
        setState(() {
          _published = false;
          _error = 'Não foi possível enviar a atividade. Verifique a internet e toque em publicar novamente.';
        });
        return;
      }
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
          icon: const Icon(Icons.arrow_back_rounded),
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
                  const SizedBox(height: 6),
                  const Text(
                    'Registre uma corrida feita em outro aplicativo. Selecione a screenshot e digite os dados manualmente.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  DashedBorder(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    fill: AppColors.primary.withValues(alpha: 0.08),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: _evidence == null ? 32 : 16,
                      ),
                      child: Column(
                        children: [
                          if (_evidence == null) ...[
                            const Icon(
                              Icons.add_photo_alternate_rounded,
                              size: 40,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Print da corrida (Strava, relógio…)',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                          ] else ...[
                            SizedBox(
                              height: 160,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.controlRadius,
                                ),
                                child: EvidenceImage(evidence: _evidence!),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          OutlinedButton(
                            onPressed: _picking || _published
                                ? null
                                : _pickEvidence,
                            child: Text(
                              _picking
                                  ? 'Selecionando imagem…'
                                  : 'Selecionar screenshot',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    key: const Key('activity-distance'),
                    controller: _distance,
                    decoration: const InputDecoration(
                      labelText: 'Distância (km)',
                      hintText: '5,23',
                      prefixIcon: Icon(Icons.route_rounded),
                      errorMaxLines: 3,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: ActivityInput.validateDistance,
                    onChanged: (_) => _metricsChanged(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('activity-duration'),
                    controller: _duration,
                    decoration: const InputDecoration(
                      labelText: 'Duração (MM:SS ou HH:MM:SS)',
                      hintText: '31:45',
                      prefixIcon: Icon(Icons.timer_rounded),
                      errorMaxLines: 3,
                    ),
                    keyboardType: TextInputType.datetime,
                    validator: ActivityInput.validateDuration,
                    onChanged: (_) => _metricsChanged(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('activity-pace'),
                    controller: _pace,
                    decoration: InputDecoration(
                      labelText: 'Ritmo médio (MM:SS/km)',
                      hintText: '06:04',
                      prefixIcon: const Icon(Icons.speed_rounded),
                      errorMaxLines: 3,
                      helperText: _paceTyped ? null : 'Calculado pela distância e duração. Ajuste se o app de corrida mostrar outro valor.',
                      helperMaxLines: 2,
                    ),
                    keyboardType: TextInputType.datetime,
                    validator: ActivityInput.validatePace,
                    onChanged: (text) {
                      _paceTyped = text.trim().isNotEmpty;
                      if (!_paceTyped) {
                        _pace.text =
                            ActivityInput.suggestPace(
                              _distance.text,
                              _duration.text,
                            ) ??
                            '';
                      }
                      _changed();
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) ...[
                    _ErrorBox(message: _error!),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton.icon(
                    onPressed: _picking || _published ? null : _validate,
                    icon: const Icon(Icons.military_tech_rounded),
                    label: const Text('Validar e ver pontuação'),
                  ),
                  if (_preview case final preview?) ...[
                    const SizedBox(height: 16),
                    _PreviewCard(preview: preview),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: AppTheme.energyButton(height: 56, fontSize: 18),
                    onPressed: _preview == null || _picking || _published
                        ? null
                        : _publish,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(
                      _published ? 'Enviando…' : 'Publicar atividade',
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Validation or submission problem, shown above the actions.
class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.error.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppTheme.controlRadius),
      border: Border.all(
        color: AppColors.error.withValues(alpha: 0.3),
        width: 2,
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.warning_rounded, color: AppColors.error, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message, style: const TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
}

/// Calculated points with a count-up animation, before publishing.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.preview});
  final ActivityPreview preview;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1),
      duration: const Duration(milliseconds: 250),
      builder: (context, scale, child) => Opacity(
        opacity: ((scale - 0.95) / 0.05).clamp(0, 1),
        child: Transform.scale(scale: scale, child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(AppTheme.heroRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: AppColors.success,
                ),
                SizedBox(width: 6),
                Text(
                  'PRÉVIA DA ATIVIDADE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: preview.score),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Text(
                '$value pontos',
                style: AppFonts.numbers(size: 56, color: AppColors.accent),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${ActivityInput.formatDistance(preview.distanceKm)} × 100',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                StatTile(
                  icon: Icons.route_rounded,
                  value: ActivityInput.formatDistance(preview.distanceKm),
                  caption: 'Distância',
                ),
                const SizedBox(width: 8),
                StatTile(
                  icon: Icons.timer_rounded,
                  value: ActivityInput.formatDuration(preview.durationSeconds),
                  caption: 'Duração',
                ),
                const SizedBox(width: 8),
                StatTile(
                  icon: Icons.speed_rounded,
                  value: ActivityInput.formatPace(
                    preview.averagePaceSecondsPerKm,
                  ),
                  caption: 'Ritmo',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
