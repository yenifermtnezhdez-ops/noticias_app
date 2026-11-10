
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  final Future<void> Function() onCompleted;

  const OnboardingScreen({
    super.key,
    required this.onCompleted,
  });

  @override
  State<OnboardingScreen> createState() =>
      _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _isCompleting = false;

  

  Future<void> _completeOnboarding() async {
    if (_isCompleting) return;

    setState(() {
      _isCompleting = true;
    });

    try {
      await widget.onCompleted();
    } catch (e) {
      debugPrint('Error al completar bienvenida: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No fue posible continuar. Inténtalo nuevamente.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

 

  Widget _buildLogo(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.12),
            ),
          ),
          child: Icon(
            Icons.newspaper_rounded,
            size: 40,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'NOTICIAS APP',
          style: TextStyle(
            color: colors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.3,
          ),
        ),
      ],
    );
  }

  

  Widget _buildHero(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 26,
        horizontal: 18,
      ),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(27),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            right: 12,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 25,
              color: colors.primary.withValues(alpha: 0.35),
            ),
          ),
          Positioned(
            bottom: 4,
            left: 15,
            child: Icon(
              Icons.circle,
              size: 12,
              color: colors.primary.withValues(alpha: 0.25),
            ),
          ),
          Column(
            children: [
              Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(
                        alpha: 0.10,
                      ),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.newspaper_rounded,
                  size: 75,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 19),
              Text(
                'La información que importa',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onPrimaryContainer,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Descubre, guarda y comparte las noticias '
                'que marcan la actualidad.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onPrimaryContainer,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  

  Widget _buildFeature(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: colors.primary,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed:
            _isCompleting ? null : _completeOnboarding,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isCompleting
              ? const Row(
                  key: ValueKey('loading'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 11),
                    Text('Preparando Noticias App...'),
                  ],
                )
              : const Row(
                  key: ValueKey('start'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Comenzar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 9),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  

  @override
  Widget build(BuildContext context) {
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
              colors.primaryContainer.withValues(alpha: 0.45),
              colors.surface,
              colors.surface,
            ],
            stops: const [0, 0.4, 1],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              22,
              20,
              22,
              27,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: _buildLogo(context),
                ),

                const SizedBox(height: 27),

                _buildHero(context),

                const SizedBox(height: 25),

                Text(
                  'Todo lo que necesitas',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Una experiencia informativa diseñada para ti.',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 17),

                _buildFeature(
                  context,
                  icon: Icons.search_rounded,
                  title: 'Encuentra noticias fácilmente',
                  description:
                      'Busca información por tema o categoría.',
                ),

                const SizedBox(height: 11),

                _buildFeature(
                  context,
                  icon: Icons.bookmark_rounded,
                  title: 'Guarda tus favoritas',
                  description:
                      'Conserva las noticias que quieras consultar.',
                ),

                const SizedBox(height: 11),

                _buildFeature(
                  context,
                  icon: Icons.notifications_active_outlined,
                  title: 'Recibe notificaciones',
                  description:
                      'Mantente al día con tus temas preferidos.',
                ),

                const SizedBox(height: 25),

                _buildStartButton(context),

                const SizedBox(height: 17),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: colors.primary,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tu espacio para mantenerte informado.',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
