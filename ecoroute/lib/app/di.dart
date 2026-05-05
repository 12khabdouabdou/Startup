import 'package:get_it/get_it.dart';

import '../auth/repository/auth_repository.dart';
import '../waste/repository/listing_repository.dart';
import '../booking/repository/booking_repository.dart';
import '../chat/repository/chat_repository.dart';
import 'supabase_client.dart';
import 'dio_client.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Core services
  getIt.registerLazySingleton<SupabaseClientInstance>(() => SupabaseClientInstance());
  getIt.registerLazySingleton<DioClient>(() => DioClient());
  
  // Repositories
  getIt.registerLazySingleton(() => AuthRepository());
  getIt.registerLazySingleton(() => ListingRepository());
  getIt.registerLazySingleton(() => BookingRepository());
  getIt.registerLazySingleton(() => ChatRepository());
}
