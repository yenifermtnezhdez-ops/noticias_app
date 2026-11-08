
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String _onboardingKey = 'onboarding_completed';

  late Future<bool> _onboardingFuture;

  bool _hasCompletedOnboarding = false;

  @override
  void initState() {
    super.initState();

    _onboardingFuture = _loadOnboardingStatus();
  }
  Future<bool> _loadOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return prefs.getBool(_onboardingKey) ?? false;
    } catch (e) {
      debugPrint('Error al consultar onboarding: $e');
      return false;
    }
  }
  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(_onboardingKey, true);
    } catch (e) {
      debugPrint('Error al guardar onboarding: $e');
    }

    if (!mounted) return;

    setState(() {
      _hasCompletedOnboarding = true;
    });
  }
  Widget _buildSplash() {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.newspaper_rounded,
                size: 65,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Noticias App',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tu espacio para mantenerte informado.',
              style: TextStyle(
                fontSize: 14,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 30),
            CircularProgressIndicator(
              color: colors.primary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    if (authProvider.isLoading) {
      return _buildSplash();
    }
    if (authProvider.isAuthenticated) {
      return const HomeScreen();
    }
    return FutureBuilder<bool>(
      future: _onboardingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSplash();
        }

        final hasSeenOnboarding =
            _hasCompletedOnboarding ||
            (snapshot.data ?? false);
        if (!hasSeenOnboarding) {
          return OnboardingScreen(
            onCompleted: _completeOnboarding,
          );
        }
        return const LoginScreen();
      },
    );
  }
}
