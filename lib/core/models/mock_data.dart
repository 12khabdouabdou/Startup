import 'package:firebase_auth/firebase_auth.dart';
import 'app_user.dart';

// Mock Firebase User class using noSuchMethod to avoid implementing all 50+ members
class MockFirebaseUser implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;
  @override
  final String? phoneNumber;
  @override
  final String? photoURL;

  MockFirebaseUser({
    required this.uid,
    this.email,
    this.displayName,
    this.phoneNumber,
    this.photoURL,
  });

  // Handle all other members dynamically (they will throw if called, which is fine for mocks)
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Static mock data
class MockData {
  static final firebaseUser = MockFirebaseUser(
    uid: 'mock-user-123',
    email: 'test@fillexchange.com',
    phoneNumber: '+15551234567',
    displayName: 'Mock Hauler',
  );

  static final haulerUser = AppUser(
    uid: 'mock-hauler-123',
    phoneNumber: '+15550000001',
    displayName: 'Mock Hauler',
    role: UserRole.hauler,
    status: UserStatus.approved,
    companyName: 'Quick Haul Logistics',
    fleetSize: 8,
    rating: 4.8,
    reviewCount: 24,
    createdAt: DateTime.now(),
  );

  static final excavatorUser = AppUser(
    uid: 'mock-excavator-123',
    phoneNumber: '+15550000002',
    displayName: 'Mock Excavator',
    role: UserRole.excavator,
    status: UserStatus.approved,
    companyName: 'Dig Deep Excavation',
    rating: 4.5,
    reviewCount: 15,
    createdAt: DateTime.now(),
  );

  static final developerUser = AppUser(
    uid: 'mock-developer-123',
    phoneNumber: '+15550000003',
    displayName: 'Mock Developer',
    role: UserRole.developer,
    status: UserStatus.approved,
    companyName: 'Urban Builders Inc.',
    rating: 5.0,
    reviewCount: 3,
    createdAt: DateTime.now(),
  );

  // Default to Hauler
  static AppUser get appUser => haulerUser;

  static User getFirebaseUser(AppUser user) {
    return MockFirebaseUser(
      uid: user.uid,
      email: 'test-${user.role.name}@fillexchange.com',
      phoneNumber: user.phoneNumber,
      displayName: user.displayName,
    );
  }
}

// Provider to hold the current mock user state
import 'package:flutter_riverpod/flutter_riverpod.dart';
final mockUserProvider = StateProvider<AppUser>((ref) => MockData.haulerUser);
