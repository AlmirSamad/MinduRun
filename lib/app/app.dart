import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

class MinduRunApp extends ConsumerWidget {
  const MinduRunApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'MinduRun',
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
