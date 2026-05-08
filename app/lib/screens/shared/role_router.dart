import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../auth/login_screen.dart';
import '../developer/developer_dashboard.dart';
import '../recycler/recycler_dashboard.dart';
import '../hauler/hauler_dashboard.dart';
import '../admin/admin_dashboard.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  Future<String?> _fetchRole() async {
    final user = SupabaseService.currentUser;
    if (user == null) return null;
    final res = await SupabaseService.client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();
    return res['role'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _fetchRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final role = snapshot.data;
        switch (role) {
          case 'developer': return const DeveloperDashboard();
          case 'hauler': return const HaulerDashboard();
          case 'recycler': return const RecyclerDashboard();
          case 'admin': return const AdminDashboard();
          default: return const LoginScreen();
        }
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (SupabaseService.currentUser != null) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const RoleRouter()));
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.recycling, size: 80, color: Colors.green),
      SizedBox(height: 16), Text('CWL', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
      SizedBox(height: 8), Text('Construction Waste Logistics'),
    ])));
  }
}
