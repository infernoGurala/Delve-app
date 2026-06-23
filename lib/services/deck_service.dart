import '../models/word_model.dart';
import '../models/deck_model.dart';

class DeckService {
  List<Word> selectRandomWords(List<Word> inventory, int count) {
    if (inventory.length < count) return [];

    final shuffled = List<Word>.from(inventory)..shuffle();
    return shuffled.take(count).toList();
  }

  Deck createDeck(List<Word> words) {
    if (words.length != 15) {
      throw Exception('Deck must have exactly 15 words');
    }

    return Deck(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startedAt: DateTime.now(),
      currentDay: 1,
      status: DeckStatus.active,
      set1WordIds: words.sublist(0, 5).map((w) => w.id).toList(),
      set2WordIds: words.sublist(5, 10).map((w) => w.id).toList(),
      set3WordIds: words.sublist(10, 15).map((w) => w.id).toList(),
    );
  }

  bool canCreateDeck(List<Word> inventory) {
    return inventory.length >= 15;
  }

  bool shouldResetDeck(DateTime lastSession, int currentDay) {
    final now = DateTime.now();
    final difference = now.difference(lastSession).inDays;
    return difference >= 1;
  }
}
