# EcoRoute - Build & Run Instructions

## Prerequisites

### 1. Install Flutter SDK

**Minimum Version:** Flutter 3.24.0+ / Dart 3.0.0+

#### macOS
```bash
brew install --cask flutter
flutter doctor
```

#### Windows
```powershell
# Download from https://flutter.dev/docs/get-started/install/windows
# Extract to C:\src\flutter
# Add C:\src\flutter\bin to PATH
flutter doctor
```

#### Linux
```bash
# Ubuntu/Debian
sudo snap install flutter --classic

# Or download manually
cd ~
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:$HOME/flutter/bin"
flutter doctor
```

### 2. Install Dependencies

```bash
cd ecoroute
flutter pub get
```

### 3. Set Up Supabase Backend

#### Create Supabase Project
1. Go to https://supabase.com
2. Create new project
3. Note your **Project URL** and **API Key**

#### Database Setup
Run the SQL migrations in `/database/migrations/` (to be created) in Supabase SQL Editor.

#### Environment Variables
Create `lib/core/config/env.dart`:
```dart
class Env {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

Or use command line:
```bash
export SUPABASE_URL='your_url'
export SUPABASE_ANON_KEY='your_key'
```

### 4. Run the App

#### Development Mode
```bash
flutter run
```

#### Specific Platform
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web
flutter run -d chrome

# Windows
flutter run -d windows
```

#### Production Build
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app/                      # App-wide configuration
│   ├── app.dart             # Main app widget
│   ├── router.dart          # GoRouter configuration
│   ├── theme.dart           # Theme configuration
│   └── di.dart              # Dependency injection
├── auth/                     # Authentication module
│   ├── bloc/                # Auth BLoC
│   ├── views/               # Login, Register screens
│   ├── repository/          # Auth repository
│   └── models/              # User models
├── core/                     # Core utilities
│   ├── network/             # Supabase, Dio clients
│   ├── offline/             # Hive, sync queue
│   ├── utils/               # Validators, formatters
│   └── widgets/             # Reusable widgets
├── waste/                    # Waste listings module
├── booking/                  # Booking module
├── map/                      # Map integration
├── chat/                     # Chat module
├── documents/                # Documents module
├── notifications/            # Notifications
├── profile/                  # Profile module
├── admin/                    # Admin panel
├── developer/                # Developer shell
├── hauler/                   # Hauler shell
└── recycler/                 # Recycler shell
```

## Testing

### Run All Tests
```bash
flutter test
```

### Run Specific Test
```bash
flutter test test/auth/auth_bloc_test.dart
```

### Coverage
```bash
flutter test --coverage
flutter pub run lcov --summary coverage/lcov.info
```

## State Management

The app uses **BLoC pattern** with `flutter_bloc`:

```dart
// Example: Access BLoC
final authBloc = context.read<AuthBloc>();
authBloc.add(AuthLoginRequested(email: 'test@test.com', password: 'password'));

// Example: Listen to state
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthLoading) return CircularProgressIndicator();
    if (state is AuthAuthenticated) return HomeScreen();
    return LoginScreen();
  },
)
```

## Navigation

Navigation uses **GoRouter** with role-based routing:

```dart
// Navigate to screen
context.go('/login');

// Navigate with parameters
context.go('/listings/$listingId');

// Navigate back
context.pop();
```

## Offline Support

The app uses **Hive** for offline storage:

```dart
// Open box
var box = await Hive.openBox('listings');

// Write data
await box.put('key', value);

// Read data
var value = box.get('key');
```

## Common Issues

### Issue: Flutter not found
**Solution:** Ensure Flutter is installed and in PATH:
```bash
export PATH="$PATH:/path/to/flutter/bin"
```

### Issue: Dependencies not resolving
**Solution:** Clear cache and re-fetch:
```bash
flutter clean
flutter pub get
```

### Issue: Android build failed
**Solution:** Update Gradle:
```bash
cd android
./gradlew wrapper --gradle-version 8.0
```

### Issue: iOS build failed
**Solution:** Update pods:
```bash
cd ios
pod update
```

## Environment Configuration

Create `.env` file or use command line:

```bash
# Development
SUPABASE_URL=https://your-dev-project.supabase.co
SUPABASE_ANON_KEY=your-dev-key

# Production
SUPABASE_URL=https://your-prod-project.supabase.co
SUPABASE_ANON_KEY=your-prod-key
```

## CI/CD

### GitHub Actions Example
```yaml
name: Build and Test

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      - run: flutter pub get
      - run: flutter test
      - run: flutter build apk --release
```

## Next Steps

1. ✅ Project structure created
2. ✅ Basic navigation setup
3. ✅ Authentication scaffolding
4. ⏳ Implement Supabase backend
5. ⏳ Build waste listing screens
6. ⏳ Implement booking flow
7. ⏳ Add map integration
8. ⏳ Build chat system
9. ⏳ Implement admin panel
10. ⏳ Add offline support
11. ⏳ Test and deploy

## Support

For issues or questions:
- Check Flutter docs: https://flutter.dev/docs
- Check Supabase docs: https://supabase.com/docs
- Check flutter_bloc: https://bloclibrary.dev
