import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<void> saveUserTheme({
    required String uid,
    required String themeName,
    required bool isDark,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'theme_name': themeName,
        'is_dark': isDark,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving theme to Firestore: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserTheme(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('theme_name')) {
          return {
            'themeName': data['theme_name'],
            'isDark': data['is_dark'] ?? false,
          };
        }
      }
    } catch (e) {
      debugPrint('Error loading theme from Firestore: $e');
    }
    return null;
  }
}
