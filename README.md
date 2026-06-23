# Delve - Vocabulary Learning App

> *"One word deeper, every day."*

A strict, discipline-driven vocabulary learning app built with Flutter and Firebase.

## Features

### ✅ Implemented
- Flutter app with 3-tab navigation (Word, Jet Words, Profile)
- Firebase services (Auth, Firestore, Groq AI)
- Deck system (15 words, 13-day cycle)
- Word inventory and archive management
- Basic UI for all screens

### 🚧 In Progress
- Daily session (5 swipe cards + 2 active cards)
- 3-second timer for passive cards
- AI validation for active cards
- Test Day (Day 13) - all 15 words tested
- Deck reset on missed day

### 📋 To Do
- Firebase project configuration
- Add google-services.json
- Add Groq API key
- Botanical background art system
- Theme system (Obsidian default)
- Onboarding flow

## Tech Stack

- **Framework:** Flutter
- **Backend:** Firebase (Auth + Firestore)
- **AI Validation:** Groq LLaMA 70B
- **Platform:** Android (primary), iOS

## Setup

See [SETUP.md](SETUP.md) for detailed instructions.

**Quick Start:**
1. Create Firebase project at https://console.firebase.google.com/
2. Add Android app with package `com.delve.app`
3. Download `google-services.json` to `android/app/`
4. Enable Authentication and Firestore
5. Get Groq API key from https://console.groq.com/
6. Update `lib/services/groq_service.dart` with your API key
7. Run: `flutter clean && flutter pub get && flutter run -d android`

## Core Philosophy

- **Strictness over convenience** - Miss one day, deck resets to Day 1
- **User-owned meanings** - Users write their own meanings
- **Art as environment** - Beautiful, book-like design
- **No noise** - No points, badges, or streak counters

## Data Structure

```
users/{uid}/
├── profile/           # User info and stats
├── inventory/         # Words waiting to be learned
├── archive/           # Learned words
└── activeDeck/        # Current 13-day deck
```

## License

MIT License
