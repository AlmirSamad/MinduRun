import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../room_providers.dart';

/// Only form input/error are local; all room mutations go through Riverpod.
class RoomFormDialog extends ConsumerStatefulWidget {
  const RoomFormDialog({super.key, required this.join});
  final bool join;
  @override
  ConsumerState<RoomFormDialog> createState() => _RoomFormDialogState();
}

class _RoomFormDialogState extends ConsumerState<RoomFormDialog> {
  final _form = GlobalKey<FormState>();
  final _input = TextEditingController();
  String? _error;
  bool _submitted = false;
  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _submit() {
    if (_submitted) return;
    if (!_form.currentState!.validate()) return;
    _submitted = true;
    try {
      final controller = ref.read(roomsControllerProvider.notifier);
      if (widget.join) {
        final room = controller.joinRoom(_input.text);
        if (room == null) {
          setState(() => _error = 'Sala não encontrada.');
          _submitted = false;
          return;
        }
      } else {
        controller.createRoom(_input.text);
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.join ? 'Sala disponível em Minhas salas.' : 'Sala criada.',
          ),
        ),
      );
    } on StateError catch (error) {
      setState(() {
        _submitted = false;
        _error = error.message;
      });
    } on ArgumentError {
      setState(() {
        _submitted = false;
        _error = 'Confira o nome da sala e tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.join ? 'Entrar com código' : 'Criar sala'),
    content: SingleChildScrollView(
      child: Form(
        key: _form,
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _input,
                autofocus: true,
                textCapitalization: widget.join
                    ? TextCapitalization.characters
                    : TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: widget.join ? 'Código da sala' : 'Nome da sala',
                  errorText: _error,
                  errorMaxLines: 3,
                ),
                maxLength: widget.join ? 12 : 40,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                validator: (value) => widget.join
                    ? ((value ?? '').trim().isEmpty
                          ? 'Informe o código da sala.'
                          : null)
                    : ref
                          .read(roomsControllerProvider.notifier)
                          .validateName(value),
                onFieldSubmitted: (_) => _submit(),
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
        onPressed: _submit,
        child: Text(widget.join ? 'Entrar' : 'Criar'),
      ),
    ],
  );
}
