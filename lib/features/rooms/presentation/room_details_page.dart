import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_widgets.dart';
import '../room_providers.dart';
import '../../competitions/presentation/competition_widgets.dart';

class RoomDetailsPage extends ConsumerWidget {
  const RoomDetailsPage({super.key, required this.roomId});
  final String roomId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final room = ref.watch(roomDetailsProvider(roomId));
    final members = ref.watch(roomMembersProvider(roomId));
    final owner = room == null
        ? null
        : ref.watch(userRepositoryProvider).getUser(room.ownerUserId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da sala'),
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: room == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Sala não encontrada ou você não participa dela.'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                HeroCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(room.name, style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Criador: ${owner?.displayName ?? room.ownerUserId}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _InviteCodeBox(code: room.inviteCode),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SectionTitle(
                  'Membros (${room.memberIds.length})',
                  icon: Icons.group_rounded,
                ),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final (index, member) in members.indexed) ...[
                        if (index > 0) const Divider(height: 1, indent: 72),
                        ListTile(
                          minTileHeight: 60,
                          leading: UserAvatar(name: member.displayName),
                          title: Text(
                            member.displayName,
                            style: theme.textTheme.titleMedium,
                          ),
                          trailing: member.id == room.ownerUserId
                              ? const StatusPill(
                                  label: 'Proprietário',
                                  color: AppColors.gold,
                                  icon: Icons.star_rounded,
                                )
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                RoomCompetitionsSection(roomId: roomId),
              ],
            ),
    );
  }
}

/// Invite code in large sporty digits with a copy action.
class _InviteCodeBox extends StatefulWidget {
  const _InviteCodeBox({required this.code});
  final String code;

  @override
  State<_InviteCodeBox> createState() => _InviteCodeBoxState();
}

class _InviteCodeBoxState extends State<_InviteCodeBox> {
  bool _copied = false;

  Future<void> _copy() async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    messenger.showSnackBar(const SnackBar(content: Text('Código copiado.')));
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.controlRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.key_rounded, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CÓDIGO DE CONVITE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  widget.code,
                  style: AppFonts.numbers(size: 24).copyWith(letterSpacing: 4),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copiar código',
            onPressed: _copy,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _copied ? Icons.check_rounded : Icons.content_copy_rounded,
                key: ValueKey(_copied),
                color: _copied ? AppColors.success : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
