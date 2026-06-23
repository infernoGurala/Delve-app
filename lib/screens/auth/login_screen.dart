import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../theme/theme_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isSubmitting = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _googleSignIn() async {
    setState(() => _isSubmitting = true);
    final auth = context.read<AuthProvider>();
    await auth.signInWithGoogle();
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent, // Show global botanical background
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // Premium Logo
                Image.asset(
                  theme.isDark ? 'logos/white.png' : 'logos/black.png',
                  width: 80,
                  height: 80,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.eco_rounded,
                    size: 80,
                    color: theme.accent,
                  ),
                ),
                const SizedBox(height: 32),

                // Artistic Title
                Text(
                  'Delve',
                  style: TextStyle(
                    fontFamily: 'OrangeAvenue',
                    fontSize: 64,
                    color: theme.text,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Minimalist Tagline
                Text(
                  'One word deeper, every day.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                    color: theme.textSecondary.withValues(alpha: 0.7),
                    letterSpacing: 0.8,
                  ),
                ),

                const Spacer(flex: 2),

                // Error Display
                if (authProvider.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      authProvider.error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: theme.accent.withValues(alpha: 0.8),
                      ),
                    ),
                  ),

                // The Only Button: Google Sign-In
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : _googleSignIn,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.text,
                      side: BorderSide(
                        color: theme.accent.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: theme.accent.withValues(alpha: 0.05),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.accent,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'G',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Continue with Google',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const Spacer(flex: 1),
                
                // Fine print
                Text(
                  'Artistic vocabulary for the refined mind.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: theme.textSecondary.withValues(alpha: 0.4),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
