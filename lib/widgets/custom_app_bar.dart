import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color resolvedFg = foregroundColor ??
        (Theme.of(context).appBarTheme.titleTextStyle?.color ?? Theme.of(context).colorScheme.onSurface);
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: resolvedFg,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      automaticallyImplyLeading: showBackButton,
      backgroundColor: backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor ?? Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: resolvedFg,
              ),
              onPressed: onBackPressed ?? () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  // If can't pop, go to home
                  context.go('/home');
                }
              },
            )
          : null,
      actions: actions,
      iconTheme: IconThemeData(color: resolvedFg),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class CustomSliverAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? flexibleSpace;
  final double expandedHeight;
  final bool pinned;
  final bool floating;
  final Color? backgroundColor;

  const CustomSliverAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
    this.flexibleSpace,
    this.expandedHeight = 200.0,
    this.pinned = true,
    this.floating = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color resolvedFg = Theme.of(context).appBarTheme.titleTextStyle?.color ?? Theme.of(context).colorScheme.onSurface;
    
    return SliverAppBar(
      // REMOVED: title property - only use FlexibleSpaceBar title to avoid collision
      automaticallyImplyLeading: showBackButton,
      backgroundColor: backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor ?? Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      expandedHeight: expandedHeight,
      pinned: pinned,
      floating: floating,
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: Colors.white, // Always white for better visibility
              ),
              onPressed: onBackPressed ?? () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            )
          : null,
      actions: actions,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: flexibleSpace,
    );
  }
}