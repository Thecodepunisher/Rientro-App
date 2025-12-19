import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rientro/core/theme/app_theme.dart';
import 'package:rientro/core/constants/app_strings.dart';
import 'package:rientro/core/constants/app_constants.dart';
import 'package:rientro/core/utils/haptics.dart';
import 'package:rientro/features/auth/providers/auth_provider.dart';
import 'package:rientro/models/user_model.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(AppStrings.settings),
      ),
      body: ListView(
        padding: AppTheme.paddingPage,
        children: [
          // User info
          userProfile.when(
            data: (user) => user != null ? _UserCard(user: user) : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          
          const SizedBox(height: 32),
          
          // Settings sections
          _SettingsSection(
            title: 'Preferenze',
            items: [
              _SettingsItem(
                icon: Icons.visibility_off_outlined,
                title: AppStrings.silentMode,
                subtitle: AppStrings.silentModeDescription,
                trailing: Consumer(
                  builder: (context, ref, _) {
                    final settings = ref.watch(userProfileProvider).value?.settings;
                    return Switch(
                      value: settings?.silentModeDefault ?? false,
                      onChanged: (value) async {
                        Haptics.selection();
                        final currentSettings = settings ?? const UserSettings();
                        await ref.read(authActionsProvider).updateSettings(
                          currentSettings.copyWith(silentModeDefault: value),
                        );
                      },
                    );
                  },
                ),
              ),
              _SettingsItem(
                icon: Icons.vibration,
                title: 'SOS con shake',
                subtitle: 'Attiva SOS scuotendo il telefono',
                trailing: Consumer(
                  builder: (context, ref, _) {
                    final settings = ref.watch(userProfileProvider).value?.settings;
                    return Switch(
                      value: settings?.shakeForSOSEnabled ?? true,
                      onChanged: (value) async {
                        Haptics.selection();
                        final currentSettings = settings ?? const UserSettings();
                        await ref.read(authActionsProvider).updateSettings(
                          currentSettings.copyWith(shakeForSOSEnabled: value),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _SettingsSection(
            title: 'Privacy e Sicurezza',
            items: [
              _SettingsItem(
                icon: Icons.lock_outline,
                title: AppStrings.privacy,
                subtitle: 'Gestisci i tuoi dati',
                onTap: () {
                  Haptics.light();
                  _showPrivacyInfo(context);
                },
              ),
              _SettingsItem(
                icon: Icons.notifications_outlined,
                title: AppStrings.notifications,
                subtitle: 'Configura le notifiche',
                onTap: () {
                  Haptics.light();
                  // TODO: Navigate to notification settings
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _SettingsSection(
            title: 'Account',
            items: [
              if (ref.watch(userProfileProvider).value?.isAnonymous == true)
                _SettingsItem(
                  icon: Icons.email_outlined,
                  title: 'Collega email',
                  subtitle: 'Crea un account permanente',
                  onTap: () {
                    Haptics.light();
                    _showLinkEmailSheet(context, ref);
                  },
                ),
              _SettingsItem(
                icon: Icons.logout,
                title: AppStrings.signOut,
                onTap: () => _confirmSignOut(context, ref),
              ),
              _SettingsItem(
                icon: Icons.delete_forever_outlined,
                title: AppStrings.deleteAccount,
                titleColor: AppTheme.error,
                onTap: () => _confirmDeleteAccount(context, ref),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _SettingsSection(
            title: 'Info',
            items: [
              _SettingsItem(
                icon: Icons.info_outline,
                title: AppStrings.about,
                subtitle: '${AppStrings.version} ${AppConstants.appVersion}',
                onTap: () {
                  Haptics.light();
                  _showAbout(context);
                },
              ),
            ],
          ),
          
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  void _showPrivacyInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const _PrivacyItem(
              icon: Icons.location_off_outlined,
              title: 'Niente tracking continuo',
              description: 'La posizione viene richiesta solo durante un rientro attivo.',
            ),
            const _PrivacyItem(
              icon: Icons.delete_sweep_outlined,
              title: 'Dati temporanei',
              description: 'I dati del rientro vengono eliminati automaticamente dopo 30 giorni.',
            ),
            const _PrivacyItem(
              icon: Icons.shield_outlined,
              title: 'Dati minimi',
              description: 'Raccogliamo solo le informazioni necessarie per la tua sicurezza.',
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    Haptics.warning();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.signOut),
        content: const Text('Sei sicuro di voler uscire?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authActionsProvider).signOut();
            },
            child: const Text(AppStrings.signOut),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    Haptics.error();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteAccount),
        content: const Text(
          'Questa azione è irreversibile. Tutti i tuoi dati verranno eliminati permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(authActionsProvider).deleteAccount();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(AppStrings.errorGeneric),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }

  void _showLinkEmailSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _LinkEmailSheet(),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppStrings.appName,
      applicationVersion: AppConstants.appVersion,
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppTheme.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.shield_outlined,
          size: 32,
          color: AppTheme.accent,
        ),
      ),
      children: [
        const Text(
          'RIENTRO è un\'app di sicurezza personale che monitora i tuoi spostamenti e avvisa i tuoi contatti di emergenza in caso di necessità.',
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.name[0].toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? (user.isAnonymous ? 'Account anonimo' : ''),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
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

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _SettingsSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.textSecondary,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: AppTheme.borderRadiusMedium,
          ),
          child: Column(
            children: items.map((item) {
              final isLast = item == items.last;
              return Column(
                children: [
                  item,
                  if (!isLast)
                    const Divider(
                      height: 1,
                      indent: 56,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: titleColor ?? AppTheme.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            )
          : null,
      trailing: trailing ?? (onTap != null
          ? const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
            )
          : null),
    );
  }
}

class _PrivacyItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PrivacyItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppTheme.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
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

class _LinkEmailSheet extends ConsumerStatefulWidget {
  const _LinkEmailSheet();

  @override
  ConsumerState<_LinkEmailSheet> createState() => _LinkEmailSheetState();
}

class _LinkEmailSheetState extends ConsumerState<_LinkEmailSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    Haptics.medium();

    try {
      await ref.read(authActionsProvider).linkAnonymousToEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        Haptics.success();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account collegato con successo!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      Haptics.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.errorGeneric),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          24 + MediaQuery.of(context).padding.bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHighlight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Collega email',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Crea un account permanente per non perdere i tuoi dati.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: AppStrings.email,
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return 'Email non valida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: AppStrings.password,
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Minimo 6 caratteri';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _link,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.textOnAccent,
                        ),
                      )
                    : const Text('Collega account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

