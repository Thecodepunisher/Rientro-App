import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rientro/core/theme/app_theme.dart';
import 'package:rientro/core/constants/app_strings.dart';
import 'package:rientro/core/constants/app_constants.dart';
import 'package:rientro/core/utils/haptics.dart';
import 'package:rientro/features/rientro/providers/rientro_provider.dart';
import 'package:rientro/features/contacts/providers/contacts_provider.dart';
import 'package:rientro/features/settings/screens/settings_screen.dart';
import 'package:rientro/widgets/common/app_button.dart';
import 'package:rientro/widgets/common/status_indicator.dart';
import 'package:rientro/models/rientro_model.dart';
import 'package:intl/intl.dart';

class ActiveRientroScreen extends ConsumerStatefulWidget {
  const ActiveRientroScreen({super.key});

  @override
  ConsumerState<ActiveRientroScreen> createState() => _ActiveRientroScreenState();
}

class _ActiveRientroScreenState extends ConsumerState<ActiveRientroScreen> {
  bool _isCompleting = false;
  bool _isCancelling = false;
  bool _showSOSConfirm = false;

  Future<void> _handleCheckIn(String rientroId) async {
    Haptics.success();
    try {
      await ref.read(rientroActionsProvider).confirmCheckIn(rientroId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in confermato ✓'),
            backgroundColor: AppTheme.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      Haptics.error();
    }
  }

  Future<void> _handleComplete(String rientroId) async {
    setState(() => _isCompleting = true);
    Haptics.success();
    
    try {
      await ref.read(rientroActionsProvider).completeRientro(rientroId);
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
        setState(() => _isCompleting = false);
      }
    }
  }

  Future<void> _handleCancel(String rientroId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.cancelRientro),
        content: const Text(AppStrings.confirmCancel),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);
    Haptics.medium();
    
    try {
      await ref.read(rientroActionsProvider).cancelRientro(rientroId);
    } catch (e) {
      Haptics.error();
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  Future<void> _handleSOS(String rientroId) async {
    if (!_showSOSConfirm) {
      setState(() => _showSOSConfirm = true);
      Haptics.warning();
      return;
    }

    Haptics.sos();
    
    try {
      await ref.read(rientroActionsProvider).activateSOS(rientroId);
      if (mounted) {
        setState(() => _showSOSConfirm = false);
      }
    } catch (e) {
      Haptics.error();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeRientro = ref.watch(activeRientroProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: activeRientro.when(
        data: (rientro) {
          if (rientro == null) {
            return const Center(
              child: Text('Nessun rientro attivo'),
            );
          }
          return _buildActiveContent(context, rientro);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accent),
        ),
        error: (_, __) => const Center(
          child: Text(AppStrings.errorGeneric),
        ),
      ),
    );
  }

  Widget _buildActiveContent(BuildContext context, RientroModel rientro) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          _buildHeader(context, rientro),
          
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: AppTheme.paddingPage,
              child: Column(
                children: [
                  // Progress ring
                  _buildProgressRing(context, rientro),
                  
                  const SizedBox(height: 32),
                  
                  // Status message
                  _buildStatusMessage(context, rientro),
                  
                  const SizedBox(height: 32),
                  
                  // Info cards
                  _buildInfoCards(context, rientro),
                  
                  const SizedBox(height: 32),
                  
                  // Check-in button (if not emergency)
                  if (!rientro.status.isEmergency)
                    _buildCheckInButton(rientro),
                  
                  const SizedBox(height: 16),
                  
                  // Complete button
                  if (!rientro.status.isEmergency)
                    _buildCompleteButton(rientro),
                ],
              ),
            ),
          ),
          
          // Bottom: SOS button
          _buildSOSSection(rientro),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, RientroModel rientro) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Status badge
          StatusBadge(status: rientro.status),
          
          const Spacer(),
          
          // Cancel button
          if (!rientro.status.isEmergency)
            TextButton(
              onPressed: _isCancelling 
                  ? null 
                  : () => _handleCancel(rientro.id),
              child: _isCancelling
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.textSecondary,
                      ),
                    )
                  : const Text(AppStrings.cancelRientro),
            ),
          
          // Settings
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRing(BuildContext context, RientroModel rientro) {
    return Stack(
      alignment: Alignment.center,
      children: [
        RientroProgressIndicator(
          progress: rientro.progress,
          status: rientro.status,
          size: 220,
          strokeWidth: 12,
        ),
        CountdownDisplay(
          minutesRemaining: rientro.minutesRemaining,
          status: rientro.status,
        ),
      ],
    );
  }

  Widget _buildStatusMessage(BuildContext context, RientroModel rientro) {
    String message;
    Color color;
    IconData icon;

    switch (rientro.status) {
      case RientroStatus.active:
        message = AppStrings.statusActive;
        color = AppTheme.statusActive;
        icon = Icons.directions_walk;
        break;
      case RientroStatus.late:
        message = AppStrings.statusLate;
        color = AppTheme.statusLate;
        icon = Icons.warning_amber_rounded;
        break;
      case RientroStatus.emergency:
        message = AppStrings.statusEmergency;
        color = AppTheme.statusEmergency;
        icon = Icons.emergency;
        break;
      default:
        message = '';
        color = AppTheme.textSecondary;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            message,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(BuildContext context, RientroModel rientro) {
    final startTime = DateFormat('HH:mm').format(rientro.startTime);
    final endTime = DateFormat('HH:mm').format(rientro.expectedEndTime);

    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            icon: Icons.schedule,
            label: 'Partenza',
            value: startTime,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoCard(
            icon: Icons.flag_outlined,
            label: 'Arrivo previsto',
            value: endTime,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckInButton(RientroModel rientro) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _handleCheckIn(rientro.id),
        icon: const Icon(Icons.check),
        label: const Text(AppStrings.imOk),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: AppTheme.accent),
          foregroundColor: AppTheme.accent,
        ),
      ),
    );
  }

  Widget _buildCompleteButton(RientroModel rientro) {
    return AppPrimaryButton(
      label: AppStrings.arrived,
      icon: Icons.home_outlined,
      onPressed: _isCompleting ? null : () => _handleComplete(rientro.id),
      isLoading: _isCompleting,
    );
  }

  Widget _buildSOSSection(RientroModel rientro) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: rientro.status.isEmergency 
            ? AppTheme.error.withOpacity(0.1) 
            : AppTheme.surface,
        border: Border(
          top: BorderSide(
            color: rientro.status.isEmergency 
                ? AppTheme.error.withOpacity(0.3) 
                : AppTheme.border,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showSOSConfirm && !rientro.status.isEmergency) ...[
            Text(
              AppStrings.sosConfirm,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Haptics.light();
                      setState(() => _showSOSConfirm = false);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(AppStrings.sosCancel),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleSOS(rientro.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'ATTIVA SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (rientro.status.isEmergency) ...[
            const Icon(
              Icons.emergency,
              color: AppTheme.error,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.sosActivated,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.sosMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            GestureDetector(
              onLongPress: () => _handleSOS(rientro.id),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: AppTheme.borderRadiusMedium,
                  border: Border.all(
                    color: AppTheme.error.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emergency,
                      color: AppTheme.error,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tieni premuto per SOS',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

