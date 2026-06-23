import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../theme/delve_theme.dart';
import '../theme/delve_themes.dart';
import 'botanical_painter.dart';

/// Animated geometric botanical background overlay.
/// Draws flower-specific patterns behind content with a slow, 
/// mesmerising animation loop for subtle life.
class BotanicalBackground extends StatefulWidget {
  final Widget child;
  final int seed;
  final double opacity;

  const BotanicalBackground({
    super.key,
    required this.child,
    required this.seed,
    this.opacity = 0.6,
  });

  @override
  State<BotanicalBackground> createState() => _BotanicalBackgroundState();
}

class _BotanicalBackgroundState extends State<BotanicalBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20), // Very slow, ambient cycle
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Try to get theme from provider, fallback to a default dark botanical theme if not yet initialized
    final themeProvider = context.read<ThemeProvider?>();
    final theme = themeProvider?.currentTheme ?? DelveThemes.bauhiniaDark;

    final blobColor = theme.isDark
        ? theme.accent.withValues(alpha: 0.07)
        : theme.accent.withValues(alpha: 0.08);

    final inkColor = theme.botanicalInk.withValues(alpha: widget.opacity * 0.7);
    final accentColor = theme.accentSecondary.withValues(alpha: widget.opacity * 0.45);

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return RepaintBoundary(
                child: CustomPaint(
                  painter: BotanicalPainter(
                    blobColor: blobColor,
                    inkColor: inkColor,
                    accentColor: accentColor,
                    seed: widget.seed,
                    flowerType: theme.flowerType,
                    animationValue: _controller.value,
                  ),
                ),
              );
            },
          ),
        ),
        Positioned.fill(child: widget.child),
      ],
    );
  }
}
