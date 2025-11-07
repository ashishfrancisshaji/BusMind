import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomBackButton extends StatelessWidget {
  final Color? color;
  final VoidCallback? onPressed;
  final bool showText;

  const CustomBackButton({
    super.key,
    this.color,
    this.onPressed,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return TextButton(
      onPressed: onPressed ?? () => _handleBack(context),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.arrow_back_ios_rounded,
            size: 20,
            color: color ?? theme.colorScheme.onSurface,
          ),
          if (showText) ...[
            const SizedBox(width: 4),
            Text(
              'Back',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color ?? theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      // If can't pop, go to home as fallback
      context.go('/home');
    }
  }
}
