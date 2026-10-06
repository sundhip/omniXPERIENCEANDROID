import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_geometry.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final Border? border;

  const AppCard({super.key, required this.child,
    this.padding,
    this.backgroundColor,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cardWidget = Container(
      padding: padding ?? const EdgeInsets.all(AppGeometry.cardPadding),
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.surface,
        borderRadius: BorderRadius.circular(AppGeometry.radiusCard),
        border: border ?? Border.all(color: colors.border, width: 1),
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppGeometry.radiusCard),
        child: cardWidget,
      );
    }
    return cardWidget;
  }
}
