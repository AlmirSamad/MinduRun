import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../core/models/models.dart';

class EvidenceImage extends ConsumerWidget {
  const EvidenceImage({super.key, required this.evidence});
  final EvidenceRef evidence;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget error(BuildContext context, Object error, StackTrace? stack) =>
        const Center(child: Text('Não foi possível exibir a evidência.'));
    if (evidence.kind == EvidenceKind.asset) {
      return Image.asset(
        evidence.id,
        fit: BoxFit.contain,
        semanticLabel: 'Evidência da atividade',
        errorBuilder: error,
      );
    }
    final bytes = ref.watch(evidenceRepositoryProvider).getBytes(evidence);
    if (bytes == null) {
      return const Text('Evidência indisponível nesta sessão.');
    }
    return Image.memory(
      bytes,
      fit: BoxFit.contain,
      semanticLabel: 'Evidência da atividade',
      errorBuilder: error,
    );
  }
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
                Expanded(child: EvidenceImage(evidence: evidence)),
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
