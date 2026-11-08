
import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  final Future<void> Function() onCompleted;

  const OnboardingScreen({
    super.key,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                height: 190,
                width: 190,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.newspaper_rounded,
                  size: 100,
                  color: colors.onPrimaryContainer,
                ),
              ),

              const SizedBox(height: 40),

              Text(
                'Bienvenido a Noticias App',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),

              const SizedBox(height: 18),

              Text(
                'Mantente informado con las noticias más '
                'importantes desde un solo lugar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: colors.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 35),
              _buildFeature(
                context,
                Icons.search,
                'Encuentra noticias fácilmente',
              ),

              const SizedBox(height: 18),

              _buildFeature(
                context,
                Icons.bookmark_outline,
                'Guarda tus noticias favoritas',
              ),

              const SizedBox(height: 18),

              _buildFeature(
                context,
                Icons.dark_mode_outlined,
                'Disfruta de una experiencia personalizada',
              ),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    await onCompleted();
                  },
                  child: const Text(
                    'Comenzar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Tu espacio para mantenerte informado.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildFeature(
    BuildContext context,
    IconData icon,
    String title,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          color: colors.primary,
          size: 25,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
