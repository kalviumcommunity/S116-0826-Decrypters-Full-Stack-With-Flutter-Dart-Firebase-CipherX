import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Centralized Cipher-X Card component matching the reference design.
///
/// Supports pearl-white surfaces and rich wine-gradient hero variants,
/// with consistent corner radius (20px) and subtle borders.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final Border? border;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.gradient,
    this.border,
    this.borderRadius,
    this.boxShadow,
    this.width,
    this.height,
  });

  /// Factory for the dark wine hero card seen in reference Screen 2.
  factory AppCard.wineHero({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
    double? width,
    double? height,
  }) {
    return AppCard(
      key: key,
      gradient: AppColors.cardWineGradient,
      padding: padding ?? const EdgeInsets.all(18.0),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.3),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.15),
        width: 1,
      ),
      onTap: onTap,
      width: width,
      height: height,
      child: child,
    );
  }

  /// Factory for the frosted pearl card seen in reference Screen 2 & 3.
  factory AppCard.pearl({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
    double? width,
    double? height,
    Border? border,
  }) {
    return AppCard(
      key: key,
      color: AppColors.surfaceLight,
      padding: padding ?? const EdgeInsets.all(18.0),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: AppColors.shadowColor,
          blurRadius: 14,
          offset: Offset(0, 4),
        ),
      ],
      border: border ??
          Border.all(
            color: AppColors.borderLight,
            width: 1,
          ),
      onTap: onTap,
      width: width,
      height: height,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(20);
    final effectivePadding = padding ?? const EdgeInsets.all(16.0);

    Widget content = Container(
      width: width,
      height: height,
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.surfaceLight) : null,
        gradient: gradient,
        borderRadius: effectiveRadius,
        border: border ?? Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: boxShadow ??
            const [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          child: content,
        ),
      );
    }

    return content;
  }
}
