# 🚀 EcoRoute - Getting Started Guide

## What is EcoRoute?

EcoRoute is a **construction waste logistics platform** that connects three key players:
- **Developers** - Generate waste and need it removed
- **Haulers** - Transport waste from sites to recycling facilities
- **Recyclers** - Process and recycle construction waste

The app includes an **admin panel** for platform management.

---

## Quick Start

### 1. Prerequisites Check

```bash
# Install Flutter (if not already installed)
# Visit: https://flutter.dev/docs/get-started/install

# Verify installation
flutter doctor

# Should show:
# ✓ Flutter SDK
# ✓ Android Studio / VS Code
# ✓ Chrome (for web testing)
# ✓ A device (Android, iOS, or Chrome)
```

### 2. Clone & Setup

```bash
# Navigate to project
cd /root/startup/ecoroute

# Get dependencies
flutter pub get

# Run code generation (for Freezed models)
flutter pub run build_runner build --delete-conflicting-outputs

# Check for issues
flutter doctor
flutter analyze
```

### 3. Supabase Setup

```bash
# 1. Go to https://supabase.com
# 2. Create new project
# 3. Go to Project Settings > API
# 4. Copy:
#    - Project URL
#    - anon/public key
```

Create `lib/core/config/env.dart`:
```dart
class Env {
  static const String supabaseUrl = 'YOUR_PROJECT_URL';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';
}
```

### 4. Run the App

```bash
# Development mode (hot reload enabled)
flutter run

# Or specify device
flutter run -d chrome      # Web
flutter run -d android     # Android emulator/device
flutter run -d ios         # iOS simulator (macOS only)
```

---

## Project Structure

```.
ecoroute/
├── lib/
│   ├── main.dart              # Entry point
│   ├── app/                   # App configuration
│   │   ├── app.dart          # Root widget
│   │   ├── theme.dart        # Light/Dark themes
│   │   ├── router.dart       # Navigation (GoRouter)
│   │   └── di.dart           # Dependency injection
│   │
│   ├── core/                  # Shared utilities
│   │   ├── network/          # Supabase, Dio
│   │   ├── offline/          # Hive, sync queue
│   │   └── utils/            # Helpers
│   │
│   ├── auth/                 # Authentication
│   │   ├── bloc/            # Auth BLoC
│   │   ├── views/           # Login, Register, Splash
│   │   ├── repository/      # Auth logic
│   │   └── models/          # User model
│   │
│   ├── waste/               # Waste listings
│   ├── booking/             # Booking flow
│   ├── map/                 # Map integration
│   ├── chat/                # Real-time chat
│   ├── documents/           # Certificates, manifests
│   ├── notifications/       # Push notifications
│   ├── profile/             # User profiles
│   ├── admin/               # Admin panel
│   │
│   ├── developer/           # Developer shell
│   ├── hauler/              # Hauler shell
│   └── recycler/            # Recycler shell
│
├── test/                    # Test files
├── assets/                  # Images, fonts, icons
├── pubspec.yaml            # Dependencies
└── README.md               # Full documentation
```

---

## State Management (BLoC)

The app uses **BLoC pattern** for state management:

```dart
// Example: Login flow
// 1. User submits login form
context.read<AuthBloc>().add(AuthLoginRequested(
  email: 'test@example.com',
  password: 'password123',
));

// 2. BLoC processes event
// 3. State updates
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthLoading) return LoadingWidget();
    if (state is AuthAuthenticated) return HomeScreen();
    if (state is AuthError) return ErrorWidget(state.message);
    return LoginScreen();
  },
)
```

---

## Navigation

Uses **GoRouter** with role-based routing:

```dart
// Routes
/ → Redirects based on auth
/login → Login screen
/register → Register screen
/developer → Developer home
/hauler → Hauler home
/recycler → Recycler home
/admin → Admin dashboard
```

---

## Database Schema

### Key Tables

**users**
- id (UUID, PK)
- email (TEXT)
- role (developer/hauler/recycler/admin)
- company_id (UUID)

**waste_listings**
- id (UUID, PK)
- developer_id (UUID, FK)
- waste_type (TEXT)
- quantity (NUMERIC)
- latitude/longitude (DOUBLE)
- status (TEXT)

**bookings**
- id (UUID, PK)
- listing_id (UUID, FK)
- hauler_id (UUID, FK)
- recycler_id (UUID, FK)
- status (TEXT)
- pickup_lat/lng (DOUBLE)
- delivery_lat/lng (DOUBLE)

See `README.md` for full schema.

---

## Color Palette

### Light Mode
- Primary: `#1B5E20` (Forest Green)
- Accent: `#FF6D00` (Safety Orange)
- Background: `#FAFAFA`

### Dark Mode
- Primary: `#4CAF50` (Bright Green)
- Accent: `#FF9100` (Bright Orange)
- Background: `#121212`

---

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test
flutter test test/auth/auth_bloc_test.dart

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## Building for Production

### Android
```bash
# APK
flutter build apk --release

# App Bundle (Play Store)
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

---

## Troubleshooting

### Dependencies won't install
```bash
flutter clean
flutter pub get
```

### Code generation issues
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Android build fails
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### iOS build fails (macOS)
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter run
```

---

## Development Workflow

1. **Create feature branch**
   ```bash
   git checkout -b feature/waste-listings
   ```

2. **Make changes**

3. **Run tests**
   ```bash
   flutter test
   ```

4. **Check code style**
   ```bash
   flutter analyze
   ```

5. **Commit**
   ```bash
   git add .
   git commit -m "feat: add waste listing creation"
   ```

6. **Push and PR**
   ```bash
   git push origin feature/waste-listings
   ```

---

## Next Steps

### Immediate (This Session)
- [ ] Install Flutter SDK
- [ ] Run `flutter pub get`
- [ ] Set up Supabase project
- [ ] Test login/register flow
- [ ] Create first Freezed model

### Short Term
- [ ] Implement waste listing screens
- [ ] Add booking state machine
- [ ] Build map integration
- [ ] Set up chat functionality

### Long Term
- [ ] Complete all role dashboards
- [ ] Add offline sync
- [ ] Implement certificates
- [ ] Build admin panel
- [ ] Deploy to production

---

## Resources

- **Flutter Docs**: https://flutter.dev/docs
- **BLoC Library**: https://bloclibrary.dev
- **Supabase**: https://supabase.com/docs
- **GoRouter**: https://pub.dev/packages/go_router
- **Freezed**: https://pub.dev/packages/freezed

---

## Support

For questions or issues:
1. Check README.md for detailed docs
2. Check BUILD.md for build instructions
3. Check PROGRESS.md for current status
4. Review Flutter/Dart documentation

---

**Status**: Foundation complete. Ready for feature development! 🎉
