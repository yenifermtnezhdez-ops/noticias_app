
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
  static const String _onboardingKey =
      'onboarding_completed';

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
      debugPrint(
        'Error al consultar onboarding: $e',
      );

      return false;
    }
  }

  

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(_onboardingKey, true);
    } catch (e) {
      debugPrint(
        'Error al guardar onboarding: $e',
      );
    }

    if (!mounted) return;

    setState(() {
      _hasCompletedOnboarding = true;
    });
  }

  

  Widget _buildAnimatedLogo(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0.75,
        end: 1,
      ),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        width: 122,
        height: 122,
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(35),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Icon(
          Icons.newspaper_rounded,
          size: 65,
          color: colors.primary,
        ),
      ),
    );
  }

  
  Widget _buildSplash() {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.primaryContainer.withValues(alpha: 0.65),
              colors.surface,
              colors.surface,
            ],
            stops: const [0, 0.65, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAnimatedLogo(context),

                  const SizedBox(height: 28),

                  Text(
                    'Noticias App',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.7,
                    ),
                  ),

                  const SizedBox(height: 9),

                  Text(
                    'Tu espacio para mantenerte informado.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 36),

                  SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.7,
                      color: colors.primary,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    'Preparando tu experiencia...',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
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
