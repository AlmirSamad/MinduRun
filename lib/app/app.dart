import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap/providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

final _messengerKey = GlobalKey<ScaffoldMessengerState>();

class MinduRunApp extends ConsumerWidget {
  const MinduRunApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(syncMessageProvider, (_, next) {
      final message = next.value;
      if (message == null) return;
      _messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    });
    return MaterialApp.router(
      title: 'MinduRun',
      scaffoldMessengerKey: _messengerKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) => MobileShell(child: child!),
    );
  }
}

/// Mobile-first shell: on wide screens, centers the app with a phone-like
/// max width instead of stretching content edge to edge.
class MobileShell extends StatelessWidget {
  const MobileShell({super.key, required this.child});

  static const maxWidth = 480.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: ClipRect(child: child),
        ),
      ),
    );
  }
}
