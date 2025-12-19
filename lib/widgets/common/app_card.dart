import 'package:flutter/material.dart';
import 'package:rientro/core/theme/app_theme.dart';
import 'package:rientro/core/utils/haptics.dart';

/// Card base dell'app
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool hasBorder;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? AppTheme.paddingCard,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.surface,
        borderRadius: AppTheme.borderRadiusMedium,
        border: hasBorder 
            ? Border.all(color: AppTheme.border, width: 0.5) 
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: () {
          Haptics.light();
          onTap!();
        },
        child: card,
      );
    }

    return card;
  }
}

/// Card per stato del rientro
class StatusCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final Widget? trailing;
  final VoidCallback? onTap;

  const StatusCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: AppTheme.borderRadiusSmall,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Card per contatto di emergenza
class ContactCard extends StatelessWidget {
  final String name;
  final String phone;
  final bool isPrimary;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ContactCard({
    super.key,
    required this.name,
    required this.phone,
    this.isPrimary = false,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null ? () {
        Haptics.light();
        onTap!();
      } : null,
      onLongPress: onLongPress != null ? () {
        Haptics.medium();
        onLongPress!();
      } : null,
      child: AnimatedContainer(
        duration: AppTheme.durationFast,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.accent.withOpacity(0.1) 
              : AppTheme.surface,
          borderRadius: AppTheme.borderRadiusMedium,
          border: Border.all(
            color: isSelected ? AppTheme.accent : AppTheme.border,
            width: isSelected ? 2 : 0.5,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppTheme.accent 
                    : AppTheme.surfaceHighlight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _initials,
                  style: TextStyle(
                    color: isSelected 
                        ? AppTheme.textOnAccent 
                        : AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPrimary) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Primario',
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            // Checkbox se selezionabile
            if (onTap != null)
              AnimatedContainer(
                duration: AppTheme.durationFast,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: AppTheme.textOnAccent,
                        size: 16,
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

/// Card info con icona
class InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const InfoCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor ?? AppTheme.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

