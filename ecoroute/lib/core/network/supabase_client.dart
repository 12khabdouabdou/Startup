import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientInstance {
  SupabaseClient get client => Supabase.instance.client;
  
  String get currentUserId => client.auth.currentUser?.id ?? '';
  bool get isSignedIn => client.auth.currentUser != null;
}
