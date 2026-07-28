# Bracket Drop

A cyberpunk terminal Tetris game built with Flutter.

## Features
- Classic Tetris mechanics (7-Bag Randomizer, Hold piece system, Soft/Hard drop)
- Glowing green phosphor CRT terminal aesthetic
- Matrix binary particle splash & line dissolve animations on line clears
- Keyboard & touch gesture controls
- 100% fluid responsive aspect ratio layout for Web, Mobile, and Desktop

---

## 🚀 Quick Start & Deployment

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>=2.13.0` or higher)
- Google Chrome (for Web deployment)
- Visual Studio C++ Build Tools (for Windows desktop deployment)
- Android Studio / Android SDK (for Android device deployment)

### 1. Clone & Setup Dependencies

```bash
git clone https://github.com/williamy101/bracket-drop.git
cd bracket-drop
flutter pub get
```

### 2. Running Locally (Development Mode)

Check available connected devices:
```bash
flutter devices
```

Run on your preferred target platform:

```bash
# Run on Web (Chrome)
flutter run -d chrome

# Run on Windows Desktop
flutter run -d windows

# Run on Android Device / Emulator
flutter run -d android
```

### 3. Building Production Bundles

```bash
# Build Web release bundle (outputs to build/web/)
flutter build web --release

# Build Windows desktop executable (outputs to build/windows/runner/Release/)
flutter build windows --release

# Build Android APK (outputs to build/app/outputs/flutter-apk/app-release.apk)
flutter build apk --release
```

### 4. Testing & Code Quality

```bash
# Run static analysis
flutter analyze

# Run unit and widget test suite
flutter test
```

---

## 🕹️ Controls

- **Move Left / Right**: `Left` / `Right` Arrows
- **Rotate**: `Up` Arrow / Tap
- **Soft Drop**: `Down` Arrow
- **Hard Drop**: `Spacebar`
- **Hold Piece**: `C` / `Shift`
- **Pause**: `P` / `Esc`
