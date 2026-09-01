import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/haptics.dart';

/// Reusable Glass Container mapping to Apple's Frosted Material specs.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final Color? color;
  final double blurSigma;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.borderColor,
    this.color,
    this.blurSigma = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = borderRadius ?? BorderRadius.circular(20);
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: r,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (color ?? (isDark ? const Color(0xFF1E293B) : Colors.white))
                      .withValues(alpha: isDark ? 0.55 : 0.80),
                  (color ?? (isDark ? const Color(0xFF0F172A) : Colors.white))
                      .withValues(alpha: isDark ? 0.30 : 0.45),
                ],
              ),
              border: Border.all(
                color: borderColor ??
                    (isDark
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.black.withValues(alpha: 0.12)),
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Frosted Capsule Button with Apple-style spring press compression animation.
class GlassButton extends StatefulWidget {
  final Widget label;
  final VoidCallback? onPressed;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? color;

  const GlassButton({
    super.key,
    required this.label,
    this.onPressed,
    this.width,
    this.height = 50,
    this.borderRadius,
    this.color,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        AppHaptics.buttonClick();
        widget.onPressed?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GlassContainer(
          width: widget.width,
          height: widget.height,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(25),
          color: widget.color,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(child: widget.label),
        ),
      ),
    );
  }
}

/// Floating glass card container.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? color;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: padding ?? const EdgeInsets.all(18),
      margin: margin,
      borderRadius: borderRadius ?? BorderRadius.circular(24),
      color: color,
      child: child,
    );
  }
}

/// Frosted Filter Chip.
class GlassChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const GlassChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AppHaptics.selection();
        onTap();
      },
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        borderRadius: BorderRadius.circular(15),
        color: isSelected ? AppColors.primary.withValues(alpha: 0.25) : null,
        borderColor: isSelected ? AppColors.primary.withValues(alpha: 0.5) : null,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Frosted Toggle Switch.
class GlassSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const GlassSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        AppHaptics.selection();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 32,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: value
              ? AppColors.primary.withValues(alpha: 0.3)
              : (isDark ? Colors.white10 : Colors.black12),
          border: Border.all(
            color:
                value ? AppColors.primary.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: GlassContainer(
            width: 24,
            height: 24,
            borderRadius: BorderRadius.circular(12),
            color: value
                ? AppColors.primary
                : (isDark ? Colors.grey.shade400 : Colors.white),
            padding: EdgeInsets.zero,
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
