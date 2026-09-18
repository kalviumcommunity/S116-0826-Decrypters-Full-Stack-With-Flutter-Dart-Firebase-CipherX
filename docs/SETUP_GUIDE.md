# Cipher-X Developer Setup Guide

**Target Version:** v1.0.0  
**Stack:** Flutter 3.24+ / Dart 3.5+, Riverpod 2.6+, Cloud Firestore, Firebase Auth, Firebase Storage

---

## Prerequisites
1. **Flutter SDK**: 3.24.x or higher installed and on `PATH`.
2. **Dart SDK**: 3.5.x or higher.
3. **Android Studio / Xcode**: Configured for mobile development.
4. **Node.js**: (Optional) For running Firebase Emulator tests.

---

## Step-by-Step Installation

### 1. Clone & Fetch Dependencies
```bash
flutter pub get
```

### 2. Verify Code Quality & Static Analysis
```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
```

### 3. Run Automated Tests
```bash
flutter test
```

### 4. Running the App
- **Android**: Connect physical device or start Android Virtual Device (AVD), then execute `flutter run`.
- **Debug Mock Mode**: Built-in mock services allow full testing without live Firebase connection if needed.
