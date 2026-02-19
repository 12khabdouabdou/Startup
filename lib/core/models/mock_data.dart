import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_user.dart';

// Helper to create a Supabase User for mocking
User createMockSupabaseUser({
  required String uid,
  required String email,
  String? phone,
}) {
  return User(
    id: uid,
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    email: email,
    phone: phone,
    createdAt: DateTime.now().toIso8601String(),
  );
}

// Static mock data
class MockData {
  /*
  static final firebaseUser = MockFirebaseUser(
    uid: 'mock-user-123',
    email: 'test@fillexchange.com',
    phoneNumber: '+15551234567',
    displayName: 'Mock Hauler',
  );
  */

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

  static User getSupabaseUser(AppUser user) {
    return createMockSupabaseUser(
      uid: user.uid,
      email: 'test-${user.role.name}@fillexchange.com',
      phone: user.phoneNumber,
    );
  }
}

// Provider to hold the current mock user state
final mockUserProvider = StateProvider<AppUser>((ref) => MockData.haulerUser);
