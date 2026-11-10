
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final authProvider = context.read<AuthProvider>();

    try {
      final success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (!success) {
        _showMessage(
          authProvider.errorMessage ??
              'No fue posible iniciar sesión.',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        authProvider.errorMessage ??
            'Ocurrió un problema al iniciar sesión.',
        isError: true,
      );
    }
  }

  
  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    final colors = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? colors.error : colors.primary,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  
  Widget _buildBrandHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.12),
            ),
          ),
          child: Icon(
            Icons.newspaper_rounded,
            size: 43,
            color: colors.primary,
          ),
        ),

        const SizedBox(height: 15),

        Text(
          'NOTICIAS APP',
          style: TextStyle(
            color: colors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.2,
          ),
        ),

        const SizedBox(height: 24),

        Text(
          '¡Bienvenido!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),

        const SizedBox(height: 9),

        Text(
          'Tu actualidad, tus noticias, todo en un solo lugar.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 13,
            height: 1.6,
          ),
        ),
      ],
    );
  }

 

  Widget _buildEmailField(bool isLoading) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      enabled: !isLoading,
      autofillHints: const [
        AutofillHints.email,
      ],
      autocorrect: false,
      decoration: const InputDecoration(
        labelText: 'Correo electrónico',
        hintText: 'ejemplo@correo.com',
        prefixIcon: Icon(
          Icons.mail_outline_rounded,
        ),
      ),
      validator: (value) {
        final email = value?.trim() ?? '';

        if (email.isEmpty) {
          return 'Ingresa tu correo electrónico.';
        }

        final emailRegex = RegExp(
          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
        );

        if (!emailRegex.hasMatch(email)) {
          return 'Ingresa un correo electrónico válido.';
        }

        return null;
      },
    );
  }

 

  Widget _buildPasswordField(bool isLoading) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      enabled: !isLoading,
      autofillHints: const [
        AutofillHints.password,
      ],
      onFieldSubmitted: (_) => _signIn(),
      decoration: InputDecoration(
        labelText: 'Contraseña',
        hintText: 'Ingresa tu contraseña',
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
        ),
        suffixIcon: IconButton(
          onPressed: isLoading
              ? null
              : () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
          tooltip: _obscurePassword
              ? 'Mostrar contraseña'
              : 'Ocultar contraseña',
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ingresa tu contraseña.';
        }

        return null;
      },
    );
  }

 

  Widget _buildLoginButton(bool isLoading) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : _signIn,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
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
                    SizedBox(width: 12),
                    Text(
                      'Iniciando sesión...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              : const Row(
                  key: ValueKey('login'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Iniciar sesión',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 19,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(bool isLoading) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.05),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inicia sesión',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Ingresa tus datos para continuar.',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 23),

            _buildEmailField(isLoading),

            const SizedBox(height: 19),

            _buildPasswordField(isLoading),

            const SizedBox(height: 25),

            _buildLoginButton(isLoading),
          ],
        ),
      ),
    );
  }

 
  Widget _buildFooter(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_outlined,
              color: colors.primary,
              size: 17,
            ),
            const SizedBox(width: 7),
            Text(
              'Tu cuenta y tu información están protegidas.',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Noticias App · Mantente informado',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.onSurfaceVariant.withValues(
              alpha: 0.7,
            ),
            fontSize: 10,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final authProvider = context.watch<AuthProvider>();

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
            stops: const [0, 0.45, 1],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 23,
                  vertical: 28,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 56,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 440,
                      ),
                      child: AutofillGroup(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            _buildBrandHeader(context),

                            const SizedBox(height: 32),

                            _buildLoginForm(
                              authProvider.isLoading,
                            ),

                            const SizedBox(height: 27),

                            _buildFooter(context),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
