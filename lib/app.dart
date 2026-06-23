import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/deck_provider.dart';
import 'providers/inventory_provider.dart';
import 'screens/shell.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/botanical_background.dart';

import 'providers/session_provider.dart';
import 'services/firestore_service.dart';
import 'services/update_service.dart';

class DelveApp extends StatefulWidget {
  const DelveApp({super.key});

  @override
  State<DelveApp> createState() => _DelveAppState();
}

class _DelveAppState extends State<DelveApp> {
  bool _isFirstLaunch = true;
  bool _isLoadingPrefs = true;
  bool _isSplashComplete = false;
  bool _isInitialized = false;

  late AuthProvider _authProvider;
  late ThemeProvider _themeProvider;
  late DeckProvider _deckProvider;
  late InventoryProvider _inventoryProvider;
  late SessionProvider _sessionProvider;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    // 1. Initialize providers immediately so they are available for the very first build
    _authProvider = AuthProvider();
    _themeProvider = ThemeProvider();
    _deckProvider = DeckProvider();
    _inventoryProvider = InventoryProvider();
    _sessionProvider = SessionProvider();

    // 2. Start async app initialization (Firebase, Supabase config, etc.)
    _initApp();
  }
  Future<void> _initApp() async {
    // 3. Wire up auth callbacks (Providers are already created)
    _authProvider.onUserLoggedOut = () {
      _inventoryProvider.clearUserData();
      _deckProvider.clearUserData();
      _sessionProvider.endSession();
    };

    // 4. Handle Theme Sync with Firebase
    _authProvider.onUserLoggedIn = (String uid) async {
      // 1. Existing data initialization
      _inventoryProvider.initForUser(uid);
      _deckProvider.initForUser(uid);

      // 2. Fetch and apply theme from Firebase
      final themeData = await _firestoreService.getUserTheme(uid);
      if (themeData != null) {
        final newTheme = _themeProvider.getThemeByNameAndMode(
          themeData['themeName'],
          themeData['isDark'],
        );
        _themeProvider.setTheme(newTheme, saveToFirestore: false);
      } else {
        // New user or no theme saved — save current default theme 
        // immediately to ensure the 'users' collection is created.
        _firestoreService.saveUserTheme(
          uid: uid,
          themeName: _themeProvider.currentTheme.name,
          isDark: _themeProvider.currentTheme.isDark,
        );
      }
    };

    // 5. Listen for theme changes to sync to Firestore
    _themeProvider.addListener(() {
      final user = _authProvider.user;
      if (user != null && _themeProvider.shouldSyncToFirestore) {
        _firestoreService.saveUserTheme(
          uid: user.uid,
          themeName: _themeProvider.currentTheme.name,
          isDark: _themeProvider.currentTheme.isDark,
        );
      }
    });

    // 4. Check preferences
    final prefs = await SharedPreferences.getInstance();
    final hasLaunched = prefs.getBool('delve_has_launched') ?? false;

    if (mounted) {
      setState(() {
        _isFirstLaunch = !hasLaunched;
        _isLoadingPrefs = false;
        _isInitialized = true;
      });
    }

    // Minimum splash duration
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() {
          _isSplashComplete = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Wrap everything in MultiProvider to ensure providers are always available
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _themeProvider),
        ChangeNotifierProvider.value(value: _deckProvider),
        ChangeNotifierProvider.value(value: _inventoryProvider),
        ChangeNotifierProvider.value(value: _sessionProvider),
      ],
      child: Consumer3<ThemeProvider, AuthProvider, DeckProvider>(
        builder: (context, themeProvider, authProvider, deckProvider, child) {
          final theme = themeProvider.currentTheme;

          return MaterialApp(
            title: 'Delve',
            theme: theme.toThemeData(),
            debugShowCheckedModeBanner: false,
            home: UpdateTrigger(
              child: Scaffold(
                body: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topLeft,
                      radius: 1.8,
                      colors: [
                        theme.isDark 
                            ? theme.background.withValues(alpha: 0.5).withBlue(theme.background.blue + 10)
                            : theme.background.withValues(alpha: 0.9),
                        theme.background,
                      ],
                    ),
                  ),
                  child: BotanicalBackground(
                    seed: 42,
                    child: Stack(
                      children: [
                        // Only show home if everything is ready
                        if (_isInitialized && _isSplashComplete && !_isLoadingPrefs && !authProvider.isLoading)
                          _buildHome(authProvider),
                        
                        // Show splash if still initializing or waiting for splash timer
                        if (!_isInitialized || !_isSplashComplete || _isLoadingPrefs || authProvider.isLoading)
                          const SplashUI(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildHome(AuthProvider authProvider) {
    if (!authProvider.isLoggedIn) {
      return const LoginScreen();
    }

    final inventory = _inventoryProvider;
    final deckProvider = _deckProvider;

    if (!inventory.isLoaded) {
      return const SplashUI();
    }

    bool isAccountEmpty = inventory.inventory.isEmpty && 
                         inventory.archive.isEmpty && 
                         deckProvider.activeDeck == null &&
                         deckProvider.completedDecksCount == 0;

    if (_isFirstLaunch && isAccountEmpty) {
      return const OnboardingScreen();
    }

    return const AppShell();
  }
}

class UpdateTrigger extends StatefulWidget {
  final Widget child;
  const UpdateTrigger({super.key, required this.child});

  @override
  State<UpdateTrigger> createState() => _UpdateTriggerState();
}

class _UpdateTriggerState extends State<UpdateTrigger> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkAndTriggerUpdate(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
