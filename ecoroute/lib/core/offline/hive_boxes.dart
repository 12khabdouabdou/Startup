import 'package:hive_flutter/hive_flutter.dart';

Future<void> initializeHiveBoxes() async {
  await Hive.openBox('listings');
  await Hive.openBox('bookings');
  await Hive.openBox('messages');
  await Hive.openBox('sync_queue');
  await Hive.openBox('user_cache');
}
