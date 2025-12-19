import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rientro/core/theme/app_theme.dart';
import 'package:rientro/core/constants/app_strings.dart';
import 'package:rientro/core/utils/haptics.dart';
import 'package:rientro/features/rientro/providers/rientro_provider.dart';
import 'package:rientro/features/contacts/providers/contacts_provider.dart';
import 'package:rientro/widgets/common/app_button.dart';
import 'package:rientro/widgets/common/app_card.dart';

class NewRientroScreen extends ConsumerStatefulWidget {
  const NewRientroScreen({super.key});

  @override
  ConsumerState<NewRientroScreen> createState() => _NewRientroScreenState();
}

class _NewRientroScreenState extends ConsumerState<NewRientroScreen> {
  bool _isLoading = false;
  int _currentStep = 0; // 0: contacts, 1: duration, 2: options

  final List<int> _durationOptions = [15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    // Reset form
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(newRientroFormProvider.notifier).reset();
    });
  }

  Future<void> _startRientro() async {
    final form = ref.read(newRientroFormProvider);
    if (!form.isValid) return;

    setState(() => _isLoading = true);
    Haptics.medium();

    try {
      final rientro = await ref.read(rientroActionsProvider).startRientro(
        durationMinutes: form.durationMinutes,
        contactIds: form.selectedContactIds,
        destinationName: form.destinationName,
        destinationLocation: form.destinationLocation,
        silentMode: form.silentMode,
      );

      if (rientro != null && mounted) {
        Haptics.success();
        Navigator.of(context).pop();
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
    final form = ref.watch(newRientroFormProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(AppStrings.newRientro),
        leading: IconButton(
          onPressed: () {
            Haptics.light();
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.close),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          
          // Content
          Expanded(
            child: AnimatedSwitcher(
              duration: AppTheme.durationMedium,
              child: _buildStepContent(),
            ),
          ),
          
          // Bottom actions
          _buildBottomActions(form),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.accent : AppTheme.surfaceHighlight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _ContactsStep(key: const ValueKey(0));
      case 1:
        return _DurationStep(
          key: const ValueKey(1),
          durationOptions: _durationOptions,
        );
      case 2:
        return _OptionsStep(key: const ValueKey(2));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomActions(NewRientroForm form) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(
            color: AppTheme.border.withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: AppButton(
                label: AppStrings.back,
                isOutlined: true,
                onPressed: () {
                  Haptics.light();
                  setState(() => _currentStep--);
                },
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentStep > 0 ? 2 : 1,
            child: _currentStep < 2
                ? AppPrimaryButton(
                    label: AppStrings.next,
                    onPressed: _canProceed(form) ? () {
                      Haptics.light();
                      setState(() => _currentStep++);
                    } : null,
                  )
                : AppPrimaryButton(
                    label: AppStrings.startNow,
                    icon: Icons.play_arrow_rounded,
                    onPressed: form.isValid && !_isLoading ? _startRientro : null,
                    isLoading: _isLoading,
                  ),
          ),
        ],
      ),
    );
  }

  bool _canProceed(NewRientroForm form) {
    switch (_currentStep) {
      case 0:
        return form.selectedContactIds.isNotEmpty;
      case 1:
        return form.durationMinutes > 0;
      default:
        return true;
    }
  }
}

// Step 1: Selezione contatti
class _ContactsStep extends ConsumerWidget {
  const _ContactsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsListProvider);
    final form = ref.watch(newRientroFormProvider);
    final formNotifier = ref.read(newRientroFormProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.selectContacts,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chi vuoi avvisare durante questo rientro?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: contacts.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_add_outlined,
                          size: 64,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.noContacts,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final contact = list[index];
                    final isSelected = form.selectedContactIds.contains(contact.id);

                    return ContactCard(
                      name: contact.name,
                      phone: contact.formattedPhone,
                      isPrimary: contact.isPrimary,
                      isSelected: isSelected,
                      onTap: () {
                        Haptics.selection();
                        if (isSelected) {
                          formNotifier.removeContact(contact.id);
                        } else {
                          formNotifier.addContact(contact.id);
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              ),
              error: (_, __) => const Center(
                child: Text(AppStrings.errorGeneric),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Step 2: Durata stimata
class _DurationStep extends ConsumerWidget {
  final List<int> durationOptions;

  const _DurationStep({
    super.key,
    required this.durationOptions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(newRientroFormProvider);
    final formNotifier = ref.read(newRientroFormProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.estimatedDuration,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quanto tempo pensi di impiegare?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          
          // Duration display
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: form.durationMinutes.toDouble()),
              duration: AppTheme.durationMedium,
              builder: (context, value, child) {
                final minutes = value.round();
                final hours = minutes ~/ 60;
                final mins = minutes % 60;
                
                return Text(
                  hours > 0 
                      ? '${hours}h ${mins}m' 
                      : '${mins}m',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accent,
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Duration options
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: durationOptions.map((duration) {
              final isSelected = form.durationMinutes == duration;
              final label = duration >= 60 
                  ? '${duration ~/ 60}h${duration % 60 > 0 ? " ${duration % 60}m" : ""}'
                  : '${duration}m';

              return GestureDetector(
                onTap: () {
                  Haptics.selection();
                  formNotifier.setDuration(duration);
                },
                child: AnimatedContainer(
                  duration: AppTheme.durationFast,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppTheme.accent 
                        : AppTheme.surface,
                    borderRadius: AppTheme.borderRadiusMedium,
                    border: Border.all(
                      color: isSelected 
                          ? AppTheme.accent 
                          : AppTheme.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected 
                          ? AppTheme.textOnAccent 
                          : AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Custom duration slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Oppure imposta manualmente:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.accent,
                  inactiveTrackColor: AppTheme.surfaceHighlight,
                  thumbColor: AppTheme.accent,
                  overlayColor: AppTheme.accent.withOpacity(0.2),
                ),
                child: Slider(
                  value: form.durationMinutes.toDouble(),
                  min: 5,
                  max: 180,
                  divisions: 35,
                  onChanged: (value) {
                    formNotifier.setDuration(value.round());
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Step 3: Opzioni aggiuntive
class _OptionsStep extends ConsumerWidget {
  const _OptionsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(newRientroFormProvider);
    final formNotifier = ref.read(newRientroFormProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Opzioni',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Personalizza il tuo rientro',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          
          // Silent mode
          _OptionTile(
            icon: Icons.visibility_off_outlined,
            title: AppStrings.silentMode,
            subtitle: AppStrings.silentModeDescription,
            value: form.silentMode,
            onChanged: (value) {
              Haptics.selection();
              formNotifier.setSilentMode(value);
            },
          ),
          
          const SizedBox(height: 16),
          
          // Destination (optional)
          AppCard(
            onTap: () {
              // TODO: Open destination picker
              Haptics.light();
            },
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHighlight,
                    borderRadius: AppTheme.borderRadiusSmall,
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.selectDestination,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        form.destinationName ?? 'Opzionale',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Summary
          _buildSummary(context, form),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, NewRientroForm form) {
    final hours = form.durationMinutes ~/ 60;
    final mins = form.durationMinutes % 60;
    final durationText = hours > 0 
        ? '${hours}h ${mins}m' 
        : '${mins} minuti';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(
          color: AppTheme.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Riepilogo',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _SummaryRow(
            icon: Icons.people_outline,
            label: 'Contatti',
            value: '${form.selectedContactIds.length} selezionati',
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            icon: Icons.timer_outlined,
            label: 'Durata',
            value: durationText,
          ),
          if (form.silentMode) ...[
            const SizedBox(height: 12),
            _SummaryRow(
              icon: Icons.visibility_off_outlined,
              label: 'Modalità',
              value: 'Silenziosa',
              valueColor: AppTheme.warning,
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: value 
                  ? AppTheme.warning.withOpacity(0.15) 
                  : AppTheme.surfaceHighlight,
              borderRadius: AppTheme.borderRadiusSmall,
            ),
            child: Icon(
              icon,
              color: value ? AppTheme.warning : AppTheme.textSecondary,
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
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

