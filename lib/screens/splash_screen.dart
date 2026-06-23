import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class SplashUI extends StatefulWidget {
  const SplashUI({super.key});

  @override
  State<SplashUI> createState() => _SplashUIState();
}

class _SplashUIState extends State<SplashUI> with TickerProviderStateMixin {
  late AnimationController _textController;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    // Text reveal animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _textController.forward();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;

    return Container(
      color: Colors.transparent, // Let global background show through
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Floating Gradient Overlay to ensure text legibility during splash
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [
                  theme.background.withValues(alpha: 0.2),
                  theme.background.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
          
          // Foreground Content
          Center(
            child: AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacity.value,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // The DELVE Title
                        Text(
                          'DELVE',
                          style: GoogleFonts.playfairDisplay(
                            color: theme.text,
                            fontSize: 72,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 12.0,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Subtitle
                        Text(
                          'MIND IN BLOOM',
                          style: GoogleFonts.inter(
                            color: theme.textSecondary.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 6.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

