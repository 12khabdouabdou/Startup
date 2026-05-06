import 'package:get_it/get_it.dart';

import '../auth/repository/auth_repository.dart';
import '../waste/repository/listing_repository.dart';
import '../booking/repository/booking_repository.dart';
import '../chat/repository/chat_repository.dart';
import '../core/network/supabase_client.dart';
import '../core/network/dio_client.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupDependencies() async {
  getIt.registerLazySingleton<SupabaseClientInstance>(
    () => SupabaseClientInstance(),
  );
  getIt.registerLazySingleton<DioClient>(() => DioClient());

  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository());
  getIt.registerLazySingleton<ListingRepository>(() => ListingRepository());
  getIt.registerLazySingleton<BookingRepository>(() => BookingRepository());
  getIt.registerLazySingleton<ChatRepository>(() => ChatRepository());
}
