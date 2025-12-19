import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rientro/core/theme/app_theme.dart';
import 'package:rientro/core/constants/app_strings.dart';
import 'package:rientro/core/utils/haptics.dart';
import 'package:rientro/features/auth/providers/auth_provider.dart';
import 'package:rientro/features/rientro/providers/rientro_provider.dart';
import 'package:rientro/features/contacts/providers/contacts_provider.dart';
import 'package:rientro/features/rientro/screens/active_rientro_screen.dart';
import 'package:rientro/features/rientro/screens/new_rientro_screen.dart';
import 'package:rientro/features/contacts/screens/contacts_screen.dart';
import 'package:rientro/features/settings/screens/settings_screen.dart';
import 'package:rientro/widgets/common/app_button.dart';
import 'package:rientro/widgets/common/app_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRientro = ref.watch(activeRientroProvider);
    final hasContacts = ref.watch(hasContactsProvider);
    final userProfile = ref.watch(userProfileProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: activeRientro.when(
          data: (rientro) {
            // Se c'è un rientro attivo, mostra la schermata attiva
            if (rientro != null && rientro.status.isActive) {
              return const ActiveRientroScreen();
            }
            
            // Altrimenti mostra la home normale
            return _HomeContent(
              userName: userProfile.value?.name ?? 'Utente',
              hasContacts: hasContacts,
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.accent),
          ),
          error: (_, __) => _HomeContent(
            userName: userProfile.value?.name ?? 'Utente',
            hasContacts: hasContacts,
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  final String userName;
  final bool hasContacts;

  const _HomeContent({
    required this.userName,
    required this.hasContacts,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          floating: true,
          backgroundColor: AppTheme.background,
          title: const Text(
            AppStrings.homeTitle,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Haptics.light();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        
        // Content
        SliverPadding(
          padding: AppTheme.paddingPage,
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Saluto
              _buildGreeting(context),
              
              const SizedBox(height: 32),
              
              // Stato sicurezza
              _buildSafetyStatus(context),
              
              const SizedBox(height: 32),
              
              // CTA principale
              if (hasContacts)
                _buildStartButton(context)
              else
                _buildAddContactsPrompt(context),
              
              const SizedBox(height: 32),
              
              // Quick actions
              _buildQuickActions(context),
              
              const SizedBox(height: 32),
              
              // Contatti rapidi
              _buildContactsSection(context, ref),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Buongiorno';
    } else if (hour < 18) {
      greeting = 'Buon pomeriggio';
    } else {
      greeting = 'Buonasera';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          userName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyStatus(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accent.withOpacity(0.15),
            AppTheme.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: AppTheme.borderRadiusLarge,
        border: Border.all(
          color: AppTheme.accent.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppTheme.accent,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.safeMessage,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.noActiveRientro,
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

  Widget _buildStartButton(BuildContext context) {
    return AppPrimaryButton(
      label: AppStrings.startRientro,
      icon: Icons.play_arrow_rounded,
      onPressed: () {
        Haptics.medium();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NewRientroScreen()),
        );
      },
    );
  }

  Widget _buildAddContactsPrompt(BuildContext context) {
    return StatusCard(
      title: AppStrings.noContacts,
      subtitle: AppStrings.addContactHint,
      icon: Icons.person_add_outlined,
      color: AppTheme.warning,
      trailing: const Icon(
        Icons.chevron_right,
        color: AppTheme.textSecondary,
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ContactsScreen()),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.people_outline,
            label: 'Contatti',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ContactsScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.history,
            label: 'Cronologia',
            onTap: () {
              // TODO: Navigate to history
              Haptics.light();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactsSection(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsListProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.emergencyContacts,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ContactsScreen()),
                );
              },
              child: const Text('Gestisci'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        contacts.when(
          data: (list) {
            if (list.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              children: list.take(3).map((contact) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ContactCard(
                    name: contact.name,
                    phone: contact.formattedPhone,
                    isPrimary: contact.isPrimary,
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.accent),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Haptics.light();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: AppTheme.borderRadiusMedium,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppTheme.textSecondary,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

