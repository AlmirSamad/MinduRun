import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../room_providers.dart';

/// Opened by an invite link (`mindurun://open/join/CODE`): joins the room
/// and goes to it. A room created seconds ago may not be synced yet, so the
/// user can retry.
class JoinInvitePage extends ConsumerStatefulWidget {
  const JoinInvitePage({super.key, required this.code});
  final String code;

  @override
  ConsumerState<JoinInvitePage> createState() => _JoinInvitePageState();
}

class _JoinInvitePageState extends ConsumerState<JoinInvitePage> {
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _join());
  }

  void _join() {
    if (!mounted) return;
    final room = ref
        .read(roomsControllerProvider.notifier)
        .joinRoom(widget.code);
    if (room == null) {
      setState(() => _notFound = true);
      return;
    }
    context.go(AppRoutes.room(room.id));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Convite')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _notFound
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sala com o código ${widget.code.toUpperCase()} não encontrada.\n'
                    'Se ela acabou de ser criada, aguarde alguns segundos e tente de novo.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      setState(() => _notFound = false);
                      _join();
                    },
                    child: const Text('Tentar novamente'),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.home),
                    child: const Text('Ir para o início'),
                  ),
                ],
              )
            : const CircularProgressIndicator(),
      ),
    ),
  );
}
