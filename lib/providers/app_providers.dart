import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waste_logistics/services/auth_service.dart';
import 'package:waste_logistics/services/driver_service.dart';
import 'package:waste_logistics/services/location_service.dart';
import 'package:waste_logistics/services/order_service.dart';
import 'package:waste_logistics/services/recycler_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService();
});

final recyclerServiceProvider = Provider<RecyclerService>((ref) {
  return RecyclerService();
});

final driverServiceProvider = Provider<DriverService>((ref) {
  return DriverService();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});
