import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroqService {
  int _currentKeyIndex = 0;
  List<String> _apiKeys = [];

  Future<void> fetchKeys() async {
    try {
      debugPrint("Fetching keys from Firestore...");
      final snapshot = await FirebaseFirestore.instance.collection('api_keys').doc('groq').get();
      if (snapshot.exists && snapshot.data() != null) {
        final List<dynamic> keys = snapshot.data()!['keys'] ?? [];
        _apiKeys = keys.cast<String>();
        _currentKeyIndex = 0;
        debugPrint("Successfully fetched ${_apiKeys.length} API keys from Firestore.");
      } else {
        debugPrint("Document api_keys/groq does not exist or has no data.");
      }
    } catch (e) {
      debugPrint("CRITICAL: Failed to fetch keys from Firestore: $e");
    }
  }

  Future<bool> validateMeaning(String word, String expected, String input) async {
    if (_apiKeys.isEmpty) await fetchKeys();
    
    // Fallback if no keys available
    if (_apiKeys.isEmpty) {
      return input.trim().toLowerCase() == expected.trim().toLowerCase();
    }

    final prompt = '''
You are an evaluator. 
Word: $word
Expected meaning conceptually: $expected
User's submitted meaning: $input

Does the user's meaning correctly capture the essence of the expected meaning? 
Reply strictly with "YES" or "NO".
''';

    while (_currentKeyIndex < _apiKeys.length) {
      final key = _apiKeys[_currentKeyIndex];
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      
      try {
        final response = await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $key',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "model": "llama-3.1-8b-instant", 
            "messages": [
              {"role": "user", "content": prompt}
            ],
            "temperature": 0.0,
            "max_tokens": 10
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final answer = data['choices'][0]['message']['content'].toString().trim().toUpperCase();
          debugPrint("Groq answer: $answer");
          return answer.contains('YES');
        } else if (response.statusCode == 429) {
          debugPrint("Key rate limited! Switching to next key...");
          _currentKeyIndex++;
          continue;
        } else if (response.statusCode == 401) {
          debugPrint("Key invalid or unauthorized (401)! Switching key...");
          _currentKeyIndex++;
          continue;
        } else {
          debugPrint("Unhandled HTTP Error: ${response.statusCode} - ${response.body}");
          return input.trim().toLowerCase() == expected.trim().toLowerCase();
        }
      } catch (e) {
        debugPrint("HTTP Exception: $e");
        return input.trim().toLowerCase() == expected.trim().toLowerCase();
      }
    }

    // All keys exhausted
    return input.trim().toLowerCase() == expected.trim().toLowerCase();
  }

  Future<String?> generateMeaning(String word) async {
    if (_apiKeys.isEmpty) await fetchKeys();
    
    if (_apiKeys.isEmpty) return null;

    final prompt = '''
You are a highly capable dictionary assistant.
Provide a concise, easy-to-understand, practical meaning for the word "$word".
Do not include any extra text, markdown, or conversational filler. Only return the actual meaning.
Keep it under 15 words if possible.
''';

    while (_currentKeyIndex < _apiKeys.length) {
      final key = _apiKeys[_currentKeyIndex];
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      
      try {
        final response = await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $key',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "model": "llama-3.1-8b-instant", 
            "messages": [
              {"role": "user", "content": prompt}
            ],
            "temperature": 0.3,
            "max_tokens": 50
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final answer = data['choices'][0]['message']['content'].toString().trim();
          return answer;
        } else if (response.statusCode == 429 || response.statusCode == 401) {
          _currentKeyIndex++;
          continue;
        } else {
          debugPrint("Unhandled HTTP Error in generateMeaning: ${response.statusCode}");
          return null;
        }
      } catch (e) {
        debugPrint("HTTP Exception in generateMeaning: $e");
        return null;
      }
    }
    return null;
  }

  Future<String?> fetchPartOfSpeech(String word) async {
    if (_apiKeys.isEmpty) await fetchKeys();
    if (_apiKeys.isEmpty) return null;

    final prompt = '''
You are a linguistic analyzer. What is the primary part of speech for the word "$word"?
Return strictly ONE of these words: noun, verb, adjective, adverb, pronoun, preposition, conjunction, interjection.
Do not include any punctuation, explanation, or extra text.
''';

    while (_currentKeyIndex < _apiKeys.length) {
      final key = _apiKeys[_currentKeyIndex];
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      
      try {
        final response = await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $key',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "model": "llama-3.1-8b-instant", 
            "messages": [
              {"role": "user", "content": prompt}
            ],
            "temperature": 0.0,
            "max_tokens": 10
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final answer = data['choices'][0]['message']['content'].toString().trim().toLowerCase();
          if (answer.contains('noun')) return 'noun';
          if (answer.contains('verb')) return 'verb';
          if (answer.contains('adjective')) return 'adjective';
          if (answer.contains('adverb')) return 'adverb';
          if (answer.contains('pronoun')) return 'pronoun';
          if (answer.contains('preposition')) return 'preposition';
          if (answer.contains('conjunction')) return 'conjunction';
          if (answer.contains('interjection')) return 'interjection';
          return answer.split(RegExp(r'\s+')).first.replaceAll(RegExp(r'[^\w\s]+'), '');
        } else if (response.statusCode == 429 || response.statusCode == 401) {
          _currentKeyIndex++;
          continue;
        } else {
          return null;
        }
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
