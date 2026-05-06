class Env {
  Env._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_ANON_KEY',
  );

  static const String osrmBaseUrl =
      'https://router.project-osrm.org/route/v1';

  static const String nominatimBaseUrl =
      'https://nominatim.openstreetmap.org';
}
