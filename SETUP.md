# Delve App Setup Instructions

## Firebase Setup (Required for full functionality)

1. **Create Firebase Project:**
   - Go to https://console.firebase.google.com/
   - Click "Add project"
   - Name it "delve-app"
   - Enable Google Analytics (optional)

2. **Add Android App to Firebase:**
   - In Firebase console, click the Android icon to add an app
   - Package name: `com.delve.app`
   - Download `google-services.json`
   - Place it in: `/home/inferno/git_repos/delve-app/android/app/google-services.json`

3. **Enable Authentication:**
   - In Firebase console, go to Authentication > Sign-in method
   - Enable "Email/Password"
   - Enable "Google" (optional)

4. **Create Firestore Database:**
   - Go to Firestore Database
   - Create database in test mode (we'll secure it later)
   - Start in test mode

5. **Get Groq API Key:**
   - Go to https://console.groq.com/
   - Create an account and get an API key
   - Replace the placeholder in `lib/services/groq_service.dart`

## Running the App

```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Run on Android device/emulator
flutter run -d android
```

## Current Status

✅ App structure created
✅ Basic UI implemented (Word, Jet Words, Profile screens)
✅ Firebase services created (Auth, Firestore, Groq)
✅ Deck system logic implemented
⚠️ Firebase project needs to be created
⚠️ google-services.json needs to be added
⚠️ Groq API key needs to be added

## Next Steps

1. Create Firebase project (see instructions above)
2. Add google-services.json to android/app/
3. Add Groq API key to lib/services/groq_service.dart
4. Test the app on Android device/emulator
5. Implement remaining features (botanical art, themes, onboarding)
