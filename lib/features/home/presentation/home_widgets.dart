import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_widgets.dart';
import '../../../core/services/pending_actions_service.dart';
import '../home_providers.dart';

/// "Pendências": votes and joins waiting for the user (hidden when empty).
class PendingActionsCard extends ConsumerWidget {
  const PendingActionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(pendingActionsProvider);
    if (actions.isEmpty) return const SizedBox.shrink();
    return Padding(
      key: const Key('pending-actions'),
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            'Pendências (${actions.length})',
            icon: Icons.notifications_active_rounded,
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final action in actions)
                  ListTile(
                    leading: Icon(switch (action.kind) {
                      PendingActionKind.vote => Icons.how_to_vote_rounded,
                      PendingActionKind.join => Icons.how_to_reg_rounded,
                    }, color: AppColors.primary),
                    title: Text(action.label),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(
                      AppRoutes.competition(action.competitionId),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Atualizado há 30 s" / "Sem conexão" / "Enviando…" (synced mode only).
class SyncStatusLine extends ConsumerStatefulWidget {
  const SyncStatusLine({super.key});

  @override
  ConsumerState<SyncStatusLine> createState() => _SyncStatusLineState();
}

class _SyncStatusLineState extends ConsumerState<SyncStatusLine> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Keeps "há X" fresh between syncs.
    _tick = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(syncStatusProvider);
    if (status == null) return const SizedBox.shrink();
    final (icon, text, color) = switch (status) {
      _ when status.offline => (
        Icons.cloud_off_rounded,
        'Sem conexão — tentando novamente',
        AppColors.warning,
      ),
      _ when status.pendingWrites > 0 => (
        Icons.cloud_upload_rounded,
        'Enviando alterações…',
        AppColors.textSecondary,
      ),
      _ => (
        Icons.cloud_done_rounded,
        syncAgeLabel(status.lastSync, DateTime.now()),
        AppColors.textSecondary,
      ),
    };
    return Padding(
      key: const Key('sync-status'),
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12, color: color)),
          ),
        ],
      ),
    );
  }
}

/// "Atualizado agora" / "há 40 s" / "há 3 min" — pull down to refresh.
String syncAgeLabel(DateTime? lastSync, DateTime now) {
  if (lastSync == null) return 'Ainda não sincronizado';
  final seconds = now.difference(lastSync).inSeconds;
  final age = seconds < 10
      ? 'agora'
      : seconds < 60
      ? 'há $seconds s'
      : 'há ${seconds ~/ 60} min';
  return 'Atualizado $age · puxe para atualizar';
}

/// Opens "Como funciona" once, right after a participant entered.
class HowItWorksOnEntry extends ConsumerStatefulWidget {
  const HowItWorksOnEntry({super.key});

  @override
  ConsumerState<HowItWorksOnEntry> createState() => _HowItWorksOnEntryState();
}

class _HowItWorksOnEntryState extends ConsumerState<HowItWorksOnEntry> {
  @override
  void initState() {
    super.initState();
    final flag = ref.read(howItWorksFlagProvider);
    if (!flag.pending) return;
    flag.pending = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showHowItWorks(context);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Short rules overview, shown after entering and from the help button.
Future<void> showHowItWorks(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Como funciona'),
    content: const SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Rule(
            Icons.group_add_rounded,
            'Entre numa sala com o código do organizador e toque em '
            '"Participar" na competição.',
          ),
          _Rule(
            Icons.directions_run_rounded,
            'Depois de correr, registre a atividade com o print do seu app '
            'de corrida, a distância e a duração. O ritmo é calculado e '
            'precisa bater com o print (tolerância de 8 s/km).',
          ),
          _Rule(
            Icons.emoji_events_rounded,
            'Cada km vale 100 pontos (5,23 km = 523). O ranking soma suas '
            'corridas; no fim aparece o campeão.',
          ),
          _Rule(
            Icons.flag_rounded,
            'Viu algo estranho? Denuncie. Os outros participantes votam '
            '(mínimo de 3 votos): maioria "inválida" zera a corrida, empate '
            'mantém.',
          ),
          _Rule(
            Icons.block_rounded,
            'O mesmo print não pode ser usado duas vezes na competição.',
          ),
        ],
      ),
    ),
    actions: [
      FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Entendi'),
      ),
    ],
  ),
);

class _Rule extends StatelessWidget {
  const _Rule(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
