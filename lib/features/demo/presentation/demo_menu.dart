import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/providers.dart';
import '../demo_controller.dart';

/// Demo-only menu; hidden when data is shared through the server.
class DemoMenu extends ConsumerWidget {
  const DemoMenu({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(appModeProvider) == AppMode.synced) {
      return const SizedBox.shrink();
    }
    return PopupMenuButton<String>(
      tooltip: 'Opções da demonstração',
      onSelected: (_) => showDialog<void>(
        context: context,
        builder: (_) => const _ResetDemoDialog(),
      ),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'reset', child: Text('Resetar demonstração')),
      ],
    );
  }
}

class _ResetDemoDialog extends ConsumerStatefulWidget {
  const _ResetDemoDialog();
  @override
  ConsumerState<_ResetDemoDialog> createState() => _ResetDemoDialogState();
}

class _ResetDemoDialogState extends ConsumerState<_ResetDemoDialog> {
  bool _submitted = false;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Resetar demonstração?'),
    content: const SingleChildScrollView(
      child: Text(
        'Todas as alterações realizadas nesta sessão serão descartadas. Você voltará à seleção de usuário.',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _submitted
            ? null
            : () {
                if (_submitted) return;
                _submitted = true;
                Navigator.of(context).pop();
                ref.read(demoControllerProvider.notifier).reset();
              },
        child: const Text('Resetar'),
      ),
    ],
  );
}
