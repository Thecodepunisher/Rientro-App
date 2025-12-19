import 'package:flutter/material.dart';
import 'package:rientro/core/theme/app_theme.dart';
import 'package:rientro/core/constants/app_constants.dart';

/// Indicatore di stato animato per il rientro
class StatusIndicator extends StatefulWidget {
  final RientroStatus status;
  final double size;

  const StatusIndicator({
    super.key,
    required this.status,
    this.size = 12,
  });

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    if (widget.status.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status.isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.status.isActive) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.status) {
      case RientroStatus.active:
        return AppTheme.statusActive;
      case RientroStatus.late:
        return AppTheme.statusLate;
      case RientroStatus.emergency:
        return AppTheme.statusEmergency;
      case RientroStatus.completed:
        return AppTheme.statusActive;
      case RientroStatus.cancelled:
        return AppTheme.statusInactive;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _color.withOpacity(_animation.value),
            shape: BoxShape.circle,
            boxShadow: widget.status.isActive
                ? [
                    BoxShadow(
                      color: _color.withOpacity(0.4 * _animation.value),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }
}

/// Badge di stato testuale
class StatusBadge extends StatelessWidget {
  final RientroStatus status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  Color get _backgroundColor {
    switch (status) {
      case RientroStatus.active:
        return AppTheme.statusActive.withOpacity(0.15);
      case RientroStatus.late:
        return AppTheme.statusLate.withOpacity(0.15);
      case RientroStatus.emergency:
        return AppTheme.statusEmergency.withOpacity(0.15);
      case RientroStatus.completed:
        return AppTheme.statusActive.withOpacity(0.15);
      case RientroStatus.cancelled:
        return AppTheme.statusInactive.withOpacity(0.15);
    }
  }

  Color get _textColor {
    switch (status) {
      case RientroStatus.active:
        return AppTheme.statusActive;
      case RientroStatus.late:
        return AppTheme.statusLate;
      case RientroStatus.emergency:
        return AppTheme.statusEmergency;
      case RientroStatus.completed:
        return AppTheme.statusActive;
      case RientroStatus.cancelled:
        return AppTheme.statusInactive;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusIndicator(status: status, size: 8),
          const SizedBox(width: 8),
          Text(
            status.label,
            style: TextStyle(
              color: _textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Indicatore di progresso circolare per il rientro
class RientroProgressIndicator extends StatelessWidget {
  final double progress;
  final RientroStatus status;
  final double size;
  final double strokeWidth;

  const RientroProgressIndicator({
    super.key,
    required this.progress,
    required this.status,
    this.size = 200,
    this.strokeWidth = 8,
  });

  Color get _progressColor {
    if (progress > 1.0) return AppTheme.statusLate;
    switch (status) {
      case RientroStatus.active:
        return AppTheme.statusActive;
      case RientroStatus.late:
        return AppTheme.statusLate;
      case RientroStatus.emergency:
        return AppTheme.statusEmergency;
      default:
        return AppTheme.statusActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              backgroundColor: AppTheme.surfaceHighlight,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.transparent,
              ),
            ),
          ),
          // Progress circle
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
              duration: AppTheme.durationMedium,
              curve: AppTheme.curveDefault,
              builder: (context, value, child) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: strokeWidth,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
                  strokeCap: StrokeCap.round,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Timer countdown display
class CountdownDisplay extends StatelessWidget {
  final int minutesRemaining;
  final RientroStatus status;

  const CountdownDisplay({
    super.key,
    required this.minutesRemaining,
    required this.status,
  });

  String get _timeString {
    final isNegative = minutesRemaining < 0;
    final absMinutes = minutesRemaining.abs();
    final hours = absMinutes ~/ 60;
    final minutes = absMinutes % 60;
    
    String timeStr;
    if (hours > 0) {
      timeStr = '${hours}h ${minutes}m';
    } else {
      timeStr = '${minutes}m';
    }
    
    return isNegative ? '+$timeStr' : timeStr;
  }

  Color get _color {
    if (minutesRemaining < 0) return AppTheme.statusLate;
    if (minutesRemaining <= 5) return AppTheme.warning;
    return AppTheme.textPrimary;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _timeString,
          style: TextStyle(
            color: _color,
            fontSize: 48,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          minutesRemaining < 0 ? 'In ritardo' : 'Rimanenti',
          style: TextStyle(
            color: _color.withOpacity(0.7),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

