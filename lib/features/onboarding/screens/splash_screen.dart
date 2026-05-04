import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase_service.dart';
import '../../dashboard/dashboard_screen.dart';
import 'auth_screen.dart';
import 'setup_wizard_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Artificial delay for splash aesthetic
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    final supabase = ref.read(supabaseServiceProvider);
    final user = supabase.currentUser;

    if (user == null) {
      _navigate(const AuthScreen());
      return;
    }

    try {
      final profile = await supabase.getUserProfile(user.id);
      if (profile == null || profile['persona_id'] == null) {
        _navigate(const SetupWizardScreen());
      } else {
        _navigate(const DashboardScreen());
      }
    } catch (e) {
      // If profile fails, assume setup is needed
      _navigate(const SetupWizardScreen());
    }
  }

  void _navigate(Widget screen) {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Image.asset(
          'assets/images/splash_screen.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
