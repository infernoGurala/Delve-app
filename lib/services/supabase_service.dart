import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/word_model.dart';
import '../models/deck_model.dart';

/// SupabaseService handles persistent data storage for Delve.
///
/// NOTE: Refactored to run on top of Firebase Firestore to resolve the defunct 
/// Supabase backend and provide a robust offline-first cloud sync experience.
class SupabaseService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  // ---------------------------------------------------------------------------
  // DateTime conversion helpers
  // ---------------------------------------------------------------------------

  DateTime _toDateTime(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.parse(val);
    return DateTime.now();
  }

  DateTime? _toDateTimeNullable(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.parse(val);
    return null;
  }

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------

  /// Create or update the user's profile row. Called after sign-in/register.
  Future<void> upsertProfile({
    required String uid,
    required String displayName,
    required String email,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'display_name': displayName,
        'email': email,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('upsertProfile error: $e');
    }
  }

  /// Fetch the user's profile.
  Future<Map<String, dynamic>?> getProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('getProfile error: $e');
      return null;
    }
  }

  /// Increment the completed deck counter and add learned words count.
  Future<void> incrementDeckStats(String uid, int wordsLearned) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'total_decks_completed': FieldValue.increment(1),
        'total_words_learned': FieldValue.increment(wordsLearned),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('incrementDeckStats error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Inventory
  // ---------------------------------------------------------------------------

  /// Add a word to the inventory.
  Future<void> addWordToInventory(String uid, Word word) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('inventory')
        .doc(word.id)
        .set(_wordToRow(uid, word));
  }

  /// Update an existing inventory word.
  Future<void> updateInventoryWord(String uid, Word word) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('inventory')
        .doc(word.id)
        .update(_wordToRow(uid, word));
  }

  /// Delete a word from inventory.
  Future<void> deleteInventoryWord(String id) async {
    final uid = _currentUid;
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('inventory')
        .doc(id)
        .delete();
  }

  /// Fetch all inventory words for a user, ordered by newest first.
  Future<List<Word>> getInventory(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('inventory')
        .orderBy('added_at', descending: true)
        .get();
    return snapshot.docs.map((doc) => _rowToWord(doc.data())).toList();
  }

  // ---------------------------------------------------------------------------
  // Archive
  // ---------------------------------------------------------------------------

  /// Move a word to the archive (learned).
  Future<void> addWordToArchive(String uid, Word word) async {
    final archivedWord = word.copyWith(archivedAt: DateTime.now());
    final batch = _firestore.batch();
    
    final archiveDoc = _firestore
        .collection('users')
        .doc(uid)
        .collection('archive')
        .doc(word.id);
        
    final inventoryDoc = _firestore
        .collection('users')
        .doc(uid)
        .collection('inventory')
        .doc(word.id);
        
    batch.set(archiveDoc, _wordToRow(uid, archivedWord));
    batch.delete(inventoryDoc);
    
    await batch.commit();
  }

  /// Fetch all archived words for a user.
  Future<List<Word>> getArchive(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('archive')
        .orderBy('archived_at', descending: true)
        .get();
    return snapshot.docs.map((doc) => _rowToWord(doc.data())).toList();
  }

  /// Update an archived word (editing meaning/note).
  Future<void> updateArchiveWord(String uid, Word word) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('archive')
        .doc(word.id)
        .update(_wordToRow(uid, word));
  }

  /// Return a word from archive back to inventory.
  Future<void> returnToInventory(String uid, Word word) async {
    final resetWord = Word(
      id: word.id,
      word: word.word,
      meaning: word.meaning,
      aiMeaning: word.aiMeaning,
      note: word.note,
      partOfSpeech: word.partOfSpeech,
      addedAt: word.addedAt,
      failCount: word.failCount,
    );
    
    final batch = _firestore.batch();
    
    final inventoryDoc = _firestore
        .collection('users')
        .doc(uid)
        .collection('inventory')
        .doc(word.id);
        
    final archiveDoc = _firestore
        .collection('users')
        .doc(uid)
        .collection('archive')
        .doc(word.id);
        
    batch.set(inventoryDoc, _wordToRow(uid, resetWord));
    batch.delete(archiveDoc);
    
    await batch.commit();
  }

  // ---------------------------------------------------------------------------
  // Active Deck
  // ---------------------------------------------------------------------------

  /// Save or update the active deck.
  Future<void> saveActiveDeck(String uid, Deck deck) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('active_deck')
        .doc('current')
        .set({
      'id': deck.id,
      'uid': uid,
      'started_at': Timestamp.fromDate(deck.startedAt),
      'current_day': deck.currentDay,
      'status': deck.status.index,
      'set1_word_ids': deck.set1WordIds,
      'set2_word_ids': deck.set2WordIds,
      'set3_word_ids': deck.set3WordIds,
      'last_session_date': deck.lastSessionDate != null
          ? Timestamp.fromDate(deck.lastSessionDate!)
          : null,
    });
  }

  /// Fetch the user's active deck (if any).
  Future<Deck?> getActiveDeck(String uid) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('active_deck')
        .doc('current')
        .get();
        
    if (!doc.exists || doc.data() == null) return null;
    final data = doc.data()!;
    
    return Deck(
      id: data['id'],
      startedAt: _toDateTime(data['started_at']),
      currentDay: data['current_day'],
      status: DeckStatus.values[data['status']],
      set1WordIds: List<String>.from(data['set1_word_ids']),
      set2WordIds: List<String>.from(data['set2_word_ids']),
      set3WordIds: List<String>.from(data['set3_word_ids']),
      lastSessionDate: _toDateTimeNullable(data['last_session_date']),
    );
  }

  /// Delete the active deck (after completion or manual clear).
  Future<void> deleteActiveDeck(String uid) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('active_deck')
        .doc('current')
        .delete();
  }

  // ---------------------------------------------------------------------------
  // Batch operations — used during deck completion
  // ---------------------------------------------------------------------------

  /// Move multiple words from inventory to archive in one go.
  Future<void> archiveWords(String uid, List<Word> words) async {
    final batch = _firestore.batch();
    for (final word in words) {
      final archivedWord = word.copyWith(archivedAt: DateTime.now());
      
      final archiveDoc = _firestore
          .collection('users')
          .doc(uid)
          .collection('archive')
          .doc(word.id);
          
      final inventoryDoc = _firestore
          .collection('users')
          .doc(uid)
          .collection('inventory')
          .doc(word.id);
          
      batch.set(archiveDoc, _wordToRow(uid, archivedWord));
      batch.delete(inventoryDoc);
    }
    await batch.commit();
  }

  /// Return multiple failed words to inventory with incremented fail count.
  Future<void> returnFailedWords(String uid, List<Word> words) async {
    final batch = _firestore.batch();
    for (final word in words) {
      final updated = word.copyWith(failCount: word.failCount + 1);
      final doc = _firestore
          .collection('users')
          .doc(uid)
          .collection('inventory')
          .doc(word.id);
      batch.set(doc, _wordToRow(uid, updated));
    }
    await batch.commit();
  }

  /// Seed the 15 onboarding words into inventory.
  Future<void> seedOnboardingWords(String uid, List<Word> words) async {
    final batch = _firestore.batch();
    for (final word in words) {
      final doc = _firestore
          .collection('users')
          .doc(uid)
          .collection('inventory')
          .doc(word.id);
      batch.set(doc, _wordToRow(uid, word));
    }
    await batch.commit();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _wordToRow(String uid, Word word) {
    return {
      'id': word.id,
      'uid': uid,
      'word': word.word,
      'meaning': word.meaning,
      'ai_meaning': word.aiMeaning,
      'note': word.note,
      'part_of_speech': word.partOfSpeech,
      'added_at': Timestamp.fromDate(word.addedAt),
      'archived_at': word.archivedAt != null ? Timestamp.fromDate(word.archivedAt!) : null,
      'fail_count': word.failCount,
    };
  }

  Word _rowToWord(Map<String, dynamic> row) {
    return Word(
      id: row['id'],
      word: row['word'],
      meaning: row['meaning'],
      aiMeaning: row['ai_meaning'],
      note: row['note'],
      partOfSpeech: row['part_of_speech'],
      addedAt: _toDateTime(row['added_at']),
      archivedAt: _toDateTimeNullable(row['archived_at']),
      failCount: row['fail_count'] ?? 0,
    );
  }
}
