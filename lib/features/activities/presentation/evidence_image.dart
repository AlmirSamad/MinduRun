import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/models/models.dart';

class EvidenceImage extends ConsumerWidget {
  const EvidenceImage({super.key, required this.evidence});
  final EvidenceRef evidence;
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _evidenceImage(ref, evidence, BoxFit.contain);
}

/// Small square preview used in feed cards.
class EvidenceThumbnail extends ConsumerWidget {
  const EvidenceThumbnail({super.key, required this.evidence, this.size = 64});
  final EvidenceRef evidence;
  final double size;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.ink,
      borderRadius: BorderRadius.circular(AppTheme.controlRadius),
      border: Border.all(color: AppColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: _evidenceImage(ref, evidence, BoxFit.cover, compact: true),
  );
}

Widget _evidenceImage(
  WidgetRef ref,
  EvidenceRef evidence,
  BoxFit fit, {
  bool compact = false,
}) {
  Widget error(BuildContext context, Object error, StackTrace? stack) => compact
      ? const Icon(Icons.image_rounded, color: AppColors.textSecondary)
      : const Center(child: Text('Não foi possível exibir a evidência.'));
  if (evidence.kind == EvidenceKind.asset) {
    return Image.asset(
      evidence.id,
      fit: fit,
      semanticLabel: 'Evidência da atividade',
      errorBuilder: error,
    );
  }
  final bytes = ref.watch(evidenceRepositoryProvider).getBytes(evidence);
  final url = ref.watch(evidenceUrlProvider);
  if (bytes == null && evidence.kind == EvidenceKind.remote && url != null) {
    return Image.network(
      url(evidence.id),
      fit: fit,
      semanticLabel: 'Evidência da atividade',
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator()),
      errorBuilder: error,
    );
  }
  if (bytes == null) {
    return compact
        ? const Icon(Icons.image_rounded, color: AppColors.textSecondary)
        : const Text('Evidência indisponível nesta sessão.');
  }
  return Image.memory(
    bytes,
    fit: fit,
    semanticLabel: 'Evidência da atividade',
    errorBuilder: error,
  );
}

Future<void> showActivityEvidence(BuildContext context, EvidenceRef evidence) =>
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 440,
          height: MediaQuery.sizeOf(context).height * .8,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Evidência da atividade',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                    child: EvidenceImage(evidence: evidence),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
