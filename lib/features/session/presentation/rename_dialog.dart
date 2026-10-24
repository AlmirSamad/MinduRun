import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/profile_rules.dart';
import '../session_providers.dart';

/// Synced mode: lets the participant fix the name shown to others.
class RenameDialog extends ConsumerStatefulWidget {
  const RenameDialog({super.key});

  @override
  ConsumerState<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends ConsumerState<RenameDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: ref.read(currentUserProvider)?.displayName ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    ref.read(sessionControllerProvider.notifier).saveProfile(_name.text);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Nome atualizado.')));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Alterar nome'),
    content: Form(
      key: _form,
      child: TextFormField(
        key: const Key('rename-field'),
        controller: _name,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        maxLength: ProfileRules.maxNameLength,
        decoration: const InputDecoration(labelText: 'Seu nome'),
        validator: ProfileRules.validateName,
        onFieldSubmitted: (_) => _save(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _save, child: const Text('Salvar')),
    ],
  );
}
