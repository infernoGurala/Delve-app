import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

/// AuthProvider wraps Firebase Auth state and exposes it to the widget tree
/// via Provider. The app's root uses this to decide whether to show
/// the login screen or the main shell.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final SupabaseService _supabaseService = SupabaseService();

  User? _user;
  bool _isLoading = true;
  String? _error;

  /// Callback to init other providers when user logs in.
  /// Set by the app after providers are created.
  Function(String uid)? onUserLoggedIn;
  Function()? onUserLoggedOut;

  AuthProvider() {
    // Listen to Firebase auth state changes reactively
    _authService.authStateChanges.listen((user) {
      final wasLoggedIn = _user != null;
      _user = user;
      _isLoading = false;
      _error = null;
      notifyListeners();

      if (user != null && !wasLoggedIn) {
        // User just logged in — initialize data
        _onLogin(user);
      } else if (user == null && wasLoggedIn) {
        // User just logged out — clear data
        onUserLoggedOut?.call();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get uid => _user?.uid;
  String get displayName => _user?.displayName ?? _user?.email?.split('@').first ?? 'User';
  String get email => _user?.email ?? '';

  // ---------------------------------------------------------------------------
  // Post-login initialization
  // ---------------------------------------------------------------------------

  Future<void> _onLogin(User user) async {
    // Upsert profile to Supabase
    try {
      await _supabaseService.upsertProfile(
        uid: user.uid,
        displayName: user.displayName ?? user.email?.split('@').first ?? 'User',
        email: user.email ?? '',
      );
    } catch (e) {
      debugPrint('Failed to upsert profile: $e');
    }

    // Notify other providers
    onUserLoggedIn?.call(user.uid);
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      final user = await _authService.signInWithEmail(email, password);
      _setLoading(false);
      return user != null;
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyError(e.code));
      return false;
    } catch (e) {
      _setError('An unexpected error occurred.');
      return false;
    }
  }

  Future<bool> registerWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    _setLoading(true);
    try {
      final user = await _authService.registerWithEmail(
        email,
        password,
        displayName: displayName,
      );
      _setLoading(false);
      return user != null;
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyError(e.code));
      return false;
    } catch (e) {
      _setError('An unexpected error occurred.');
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      final user = await _authService.signInWithGoogle();
      _setLoading(false);
      return user != null;
    } catch (e) {
      _setError('Google sign-in failed.');
      return false;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _authService.sendPasswordReset(email);
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyError(e.code));
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  void _setLoading(bool val) {
    _isLoading = val;
    _error = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _error = msg;
    _isLoading = false;
    notifyListeners();
  }

  /// Convert Firebase error codes into user-friendly strings.
  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try later.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
