# Firebase Setup Guide for Delve App

## Project Information
- **Project Name:** delve-app
- **Project ID:** delve-app-bb660
- **Android Package:** com.delve.app

## Steps to Download google-services.json

### 1. Go to Firebase Console
Open: https://console.firebase.google.com/

### 2. Select Your Project
Click on **delve-app** (Project ID: delve-app-bb660)

### 3. Add Android App (if not already added)
- Click the **Android icon** (📱) to add an Android app
- Or if already added, click the **gear icon** ⚙️ → **Project settings** → **Your apps** section

### 4. Register App
Fill in:
- **Android package name:** `com.delve.app`
- **App nickname:** Delve Android (optional)
- **Debug signing certificate SHA-1:** (leave empty for now)

Click **Register app**

### 5. Download Configuration File
- Click **Download google-services.json**
- Save the file

### 6. Place the File
Move the downloaded file to:
```
/home/inferno/git_repos/delve-app/android/app/google-services.json
```

### 7. Enable Authentication
1. In Firebase console, go to **Authentication** (left sidebar)
2. Click **Get started**
3. Go to **Sign-in method** tab
4. Enable **Email/Password**
5. (Optional) Enable **Google**

### 8. Create Firestore Database
1. Go to **Firestore Database** (left sidebar)
2. Click **Create database**
3. Choose **Start in test mode** (we'll secure it later)
4. Select a location closest to you (e.g., `europe-west1` or `us-central1`)
5. Click **Done**

## Verify Setup

After downloading the real `google-services.json`, run:

```bash
cd /home/inferno/git_repos/delve-app
flutter clean
flutter pub get
flutter run -d android
```

## Important Notes

⚠️ **The `google-services.json` file contains:**
- Project API keys
- Firebase project configuration
- OAuth client information

⚠️ **Never commit `google-services.json` to public repositories!**
Add it to `.gitignore` if you plan to open-source this project.

## Current Status

✅ Groq API key added (from ~/API.txt)
✅ Android package name fixed: `com.delve.app`
✅ Firebase plugins added to build.gradle.kts
⚠️ Need to download real `google-services.json` from Firebase console

## Quick Test

Once you have the real `google-services.json`:

```bash
# Test on connected Android device/emulator
flutter run -d android

# Or build release APK
flutter build apk --release
```

The app should now connect to Firebase and you can test:
- User registration/login
- Adding words to inventory
- Creating decks
- Daily sessions
