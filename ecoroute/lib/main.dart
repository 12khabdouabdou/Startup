import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get_it/get_it.dart';

import 'app/app.dart';
import 'app/di.dart';
import 'core/offline/hive_boxes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  
  // Initialize Hive for offline storage
  await Hive.initFlutter();
  await initializeHiveBoxes();
  
  // Initialize dependency injection
  await setupDependencies();
  
  runApp(const EcoRouteApp());
}
