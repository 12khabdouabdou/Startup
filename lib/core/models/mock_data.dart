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

  static final appUser = AppUser(
    uid: 'mock-user-123',
    phoneNumber: '+15551234567',
    displayName: 'Mock Hauler',
    role: UserRole.hauler,
    status: UserStatus.approved,
    companyName: 'Mock Hauling Co.',
    fleetSize: 5,
    rating: 4.8,
    reviewCount: 12,
    createdAt: DateTime.now(),
  );
}
