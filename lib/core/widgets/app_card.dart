import 'package:flutter/material.dart';
import 'package:taskora/core/utils/app_constants.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final BorderSide? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorder =
        border ??
        (borderColor != null ? BorderSide(color: borderColor!) : null);

    final card = Card(
      color: color,
      shape: effectiveBorder != null
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radius16),
              side: effectiveBorder,
            )
          : null,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppConstants.space16),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radius16),
        child: card,
      );
    }

    return card;
  }
}
