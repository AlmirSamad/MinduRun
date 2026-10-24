import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/services/profile_rules.dart';
import '../../../app/theme/app_widgets.dart';
import '../session_providers.dart';
import '../../demo/presentation/demo_menu.dart';

/// Demo profile selector (simulated local session, not real login).
class UserSelectionPage extends ConsumerWidget {
  const UserSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final users = ref.watch(availableUsersProvider);

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          HeroCard(
            padding: EdgeInsets.zero,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 8, 36),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerRight,
                      child: DemoMenu(),
                    ),
                    const MinduLogo(stacked: true, height: 96),
                    const SizedBox(height: 14),
                    Text(
                      'Corra com seus amigos. Compita. Valide.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (ref.watch(appModeProvider) == AppMode.synced)
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: _NameForm(),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Quem está usando o app?',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Escolha um perfil de demonstração.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (users.isEmpty)
                    const Text(
                      'Nenhum usuário disponível.',
                      textAlign: TextAlign.center,
                    ),
                  for (final user in users)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          key: Key('select-user-${user.id}'),
                          minTileHeight: 68,
                          leading: UserAvatar(name: user.displayName),
                          title: Text(
                            user.displayName,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          onTap: () => ref
                              .read(sessionControllerProvider.notifier)
                              .selectUser(user),
                        ),
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

/// Consent shown before joining the real test (docs/07_SECURITY_PRIVACY.md).
const privacyNotice =
    'Entendo que meu nome, minhas corridas e os prints que eu enviar ficam '
    'visíveis para os participantes das minhas salas, são usados só neste '
    'teste acadêmico e serão apagados ao final dele.';

/// Synced mode: the phone's anonymous account gets the participant's name.
class _NameForm extends ConsumerStatefulWidget {
  const _NameForm();

  @override
  ConsumerState<_NameForm> createState() => _NameFormState();
}

class _NameFormState extends ConsumerState<_NameForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  bool _consented = false;
  bool _consentMissing = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final valid = _form.currentState!.validate();
    setState(() => _consentMissing = !_consented);
    if (!valid || !_consented) return;
    ref.read(sessionControllerProvider.notifier).saveProfile(_name.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Como você se chama?', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Seu nome aparece para os outros participantes da sala.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            key: const Key('participant-name'),
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            maxLength: ProfileRules.maxNameLength,
            decoration: const InputDecoration(
              labelText: 'Seu nome',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: ProfileRules.validateName,
            onFieldSubmitted: (_) => _submit(),
          ),
          CheckboxListTile(
            key: const Key('privacy-consent'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _consented,
            onChanged: (value) => setState(() {
              _consented = value ?? false;
              if (_consented) _consentMissing = false;
            }),
            title: const Text(privacyNotice),
            subtitle: _consentMissing
                ? Text(
                    'Confirme para participar do teste.',
                    style: TextStyle(color: theme.colorScheme.error),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Começar'),
          ),
        ],
      ),
    );
  }
}
