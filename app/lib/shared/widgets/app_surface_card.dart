import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.gradient,
    this.glassmorphism = false,
    this.accentColor,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;
  final bool glassmorphism;
  final Color? accentColor;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border.withValues(alpha: 0.5);
    final radius = BorderRadius.circular(borderRadius ?? AppSpacing.cardRadius);

    Widget content = Padding(padding: padding, child: child);

    if (gradient != null) {
      content = Container(
        decoration: BoxDecoration(gradient: gradient, borderRadius: radius),
        padding: padding,
        child: child,
      );
      return Container(margin: margin, child: content);
    }

    final shape = RoundedRectangleBorder(
      borderRadius: radius,
      side: BorderSide(color: borderColor, width: glassmorphism ? 0.5 : 1),
    );

    if (glassmorphism) {
      content = ClipRRect(
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.75),
            borderRadius: radius,
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.5),
            ),
          ),
          child: content,
        ),
      );
      return Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: (accentColor ?? AppColors.primary).withValues(alpha: isDark ? 0.08 : 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: content,
      );
    }

    final material = Material(
      color: surfaceColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, child: content),
    );

    if (!isDark) {
      return Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: (accentColor ?? Colors.black).withValues(alpha: accentColor != null ? 0.08 : 0.04),
              blurRadius: accentColor != null ? 16 : 10,
              offset: const Offset(0, 3),
              spreadRadius: accentColor != null ? -2 : 0,
            ),
          ],
        ),
        child: material,
      );
    }

    return Container(margin: margin, child: material);
  }
}

class AppMetricCard extends StatelessWidget {
  const AppMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primary;
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      accentColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withValues(alpha: 0.15), accent.withValues(alpha: 0.05)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: accent)),
        ],
      ),
    );
  }
}
