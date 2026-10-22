import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../core/services/competition_rules.dart';
import '../competition_providers.dart';
import 'competition_widgets.dart';

class CreateCompetitionDialog extends ConsumerStatefulWidget {
  const CreateCompetitionDialog({super.key, required this.roomId});
  final String roomId;
  @override
  ConsumerState<CreateCompetitionDialog> createState() =>
      _CreateCompetitionDialogState();
}

class _CreateCompetitionDialogState
    extends ConsumerState<CreateCompetitionDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  String? _error;
  bool _submitted = false;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool start) async {
    final initial =
        (start ? _start : _end) ?? ref.read(clockProvider)().toLocal();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200, 12, 31),
      helpText: start ? 'Data de início' : 'Data de término',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: start ? 'Horário de início' : 'Horário de término',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;
    final value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (start) {
        _start = value;
      } else {
        _end = value;
      }
      _error = null;
    });
  }

  void _submit() {
    if (_submitted) return;
    final validName = _form.currentState!.validate();
    final periodError = CompetitionRules.validatePeriod(_start, _end);
    setState(() => _error = periodError);
    if (!validName || periodError != null) return;
    try {
      _submitted = true;
      ref
          .read(competitionsControllerProvider.notifier)
          .createCompetition(
            roomId: widget.roomId,
            name: _name.text,
            startsAt: _start!,
            endsAt: _end!,
          );
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Competição criada.')));
    } on StateError catch (error) {
      setState(() {
        _submitted = false;
        _error = error.message;
      });
    } on ArgumentError {
      setState(() {
        _submitted = false;
        _error = 'Confira o nome e o período da competição.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Criar competição'),
    content: SingleChildScrollView(
      child: SizedBox(
        width: 320,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                maxLength: 50,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nome da competição',
                  errorMaxLines: 3,
                ),
                validator: CompetitionRules.validateName,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('competition-start'),
                onPressed: () => _pickDateTime(true),
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _start == null
                      ? 'Selecionar início'
                      : 'Início: ${formatCompetitionDate(_start!)}',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('competition-end'),
                onPressed: () => _pickDateTime(false),
                icon: const Icon(Icons.event),
                label: Text(
                  _end == null
                      ? 'Selecionar término'
                      : 'Término: ${formatCompetitionDate(_end!)}',
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
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
      FilledButton(onPressed: _submit, child: const Text('Criar')),
    ],
  );
}
