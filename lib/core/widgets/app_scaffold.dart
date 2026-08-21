import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/haptics.dart';

class FloatingGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const FloatingGlassAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: (isDark ? const Color(0xFF1E293B) : Colors.white)
                  .withOpacity(isDark ? 0.72 : 0.85),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AppBar(
              title: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: leading,
              actions: actions,
              automaticallyImplyLeading: false,
              primary: false,
              bottom: bottom,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(56.0 + 16.0 + (bottom?.preferredSize.height ?? 0.0));
}

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget? body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Widget? drawer;
  final bool showBack;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final VoidCallback? onBack;

  const AppScaffold({
    super.key,
    required this.title,
    this.body,
    this.floatingActionButton,
    this.actions,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.drawer,
    this.showBack = true,
    this.bottom,
    this.backgroundColor,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use sunset gradient mesh colors by default as specified in theme spec point 4
    const color1 = Color(0xFF3B82F6); // Blue
    const color2 = Color(0xFF8B5CF6); // Purple
    const color3 = Color(0xFFEC4899); // Pink
    const color4 = Color(0xFFF59E0B); // Amber

    final canPop = Navigator.of(context).canPop();
    final bool shouldShowBack = showBack && canPop;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Base solid background layer
          Positioned.fill(
            child: Container(
              color: backgroundColor ??
                  (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
            ),
          ),
          // Ambient soft pastel glow circles (Vibrant Mesh)
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color1.withOpacity(isDark ? 0.35 : 0.22),
                    color1.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.28,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color2.withOpacity(isDark ? 0.30 : 0.18),
                    color2.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -50,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color3.withOpacity(isDark ? 0.25 : 0.15),
                    color3.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: 50,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color4.withOpacity(isDark ? 0.20 : 0.12),
                    color4.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          // Glass filter overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),

          // Scaffold Content
          Scaffold(
            backgroundColor: Colors.transparent,
            extendBody: true,
            appBar: FloatingGlassAppBar(
              title: title,
              leading: shouldShowBack
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      tooltip: 'Back',
                      onPressed: onBack ?? () => Navigator.of(context).pop(),
                    )
                  : (drawer != null
                      ? Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu_rounded),
                            tooltip: 'Open Menu',
                            onPressed: () {
                              AppHaptics.buttonClick();
                              Scaffold.of(context).openDrawer();
                            },
                          ),
                        )
                      : null),
              actions: actions,
              bottom: bottom,
            ),
            body: body != null ? SafeArea(child: body!) : null,
            drawer: drawer,
            floatingActionButton: floatingActionButton,
            bottomNavigationBar: bottomNavigationBar,
            bottomSheet: bottomSheet,
          ),
        ],
      ),
    );
  }
}
