
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  final UserService _userService = UserService();
  final ImagePicker _imagePicker = ImagePicker();

  String? _imagePath;
  String _email = '';
  String? _userId;

  bool _isLoadingProfile = true;
  bool _isSaving = false;
  bool _isPickingImage = false;
  bool _isDeleting = false;

  bool get _isBusy => _isSaving || _isDeleting;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  

  Future<void> _loadProfile() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _isLoadingProfile = false;
      });
      return;
    }

    _userId = user.uid;
    _email = user.email ?? '';
    _nameController.text = user.displayName ?? '';

    try {
      final phone = await _userService.getPhone(user.uid);
      final imagePath =
          await _userService.getProfileImagePath(user.uid);

      if (!mounted) return;

      setState(() {
        _phoneController.text = phone;
        _imagePath = imagePath;
        _isLoadingProfile = false;
      });
    } catch (e) {
      debugPrint('Error al cargar el perfil: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingProfile = false;
      });

      _showMessage(
        'No fue posible cargar toda la información del perfil.',
        isError: true,
      );
    }
  }

  Future<void> _pickImage() async {
    if (_userId == null ||
        _isPickingImage ||
        _isBusy) {
      return;
    }

    setState(() {
      _isPickingImage = true;
    });

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null || !mounted) return;

      final savedPath = await _userService.saveProfileImage(
        userId: _userId!,
        image: image,
      );

      if (!mounted) return;

      setState(() {
        _imagePath = savedPath;
      });

      _showMessage('Fotografía de perfil actualizada.');
    } catch (e) {
      debugPrint('Error al seleccionar fotografía: $e');

      if (!mounted) return;

      _showMessage(
        'No fue posible guardar la fotografía.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  
  Future<void> _saveProfile() async {
    if (_isBusy || _isPickingImage) return;

    if (!_formKey.currentState!.validate()) return;

    if (_userId == null) {
      _showMessage(
        'No existe un usuario autenticado.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      final newName = _nameController.text.trim();
      final newPhone = _phoneController.text.trim();

      if (newName != (authProvider.user?.displayName ?? '')) {
        final success = await authProvider.updateDisplayName(
          name: newName,
        );

        if (!success) {
          throw Exception(
            authProvider.errorMessage ??
                'No fue posible actualizar el nombre.',
          );
        }
      }

      await _userService.savePhone(
        userId: _userId!,
        phone: newPhone,
      );

      if (!mounted) return;

      _showMessage('Tu perfil se actualizó correctamente.');
    } catch (e) {
      debugPrint('Error al guardar perfil: $e');

      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  

  Future<void> _confirmDeleteAccount() async {
    if (_isBusy) return;

    final passwordController = TextEditingController();
    final passwordFormKey = GlobalKey<FormState>();

    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: colors.error,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Eliminar cuenta'),
              ),
            ],
          ),
          content: Form(
            key: passwordFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Esta acción es permanente. Se eliminará tu cuenta '
                  'de Firebase y los datos locales de tu perfil.\n\n'
                  'Para confirmar tu identidad, introduce tu contraseña.',
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu contraseña.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              onPressed: () {
                if (passwordFormKey.currentState!.validate()) {
                  Navigator.pop(
                    dialogContext,
                    passwordController.text,
                  );
                }
              },
              child: const Text('Eliminar definitivamente'),
            ),
          ],
        );
      },
    );

    passwordController.dispose();

    if (password == null || !mounted) return;

    await _deleteAccount(password);
  }

  Future<void> _deleteAccount(String password) async {
    final authProvider = context.read<AuthProvider>();
    final userId = _userId;

    if (userId == null || _isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    final success = await authProvider.deleteAccount(
      password: password,
    );

    if (!mounted) return;

    if (!success) {
      setState(() {
        _isDeleting = false;
      });

      _showMessage(
        authProvider.errorMessage ??
            'No fue posible eliminar la cuenta.',
        isError: true,
      );
      return;
    }

    try {
      await _userService.deleteLocalProfile(userId);
    } catch (e) {
      debugPrint('Error al limpiar datos locales: $e');
    }

    if (!mounted) return;

    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );
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

  

  Widget _buildProfileImage() {
    final colors = Theme.of(context).colorScheme;

    final path = _imagePath;

    final hasImage = path != null &&
        File(path).existsSync();

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 126,
          height: 126,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.surface,
            border: Border.all(
              color: colors.primary,
              width: 2.5,
            ),
          ),
          child: ClipOval(
            child: hasImage
                ? Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person_rounded,
                        size: 68,
                        color: colors.onPrimaryContainer,
                      );
                    },
                  )
                : Container(
                    color: colors.primaryContainer,
                    child: Icon(
                      Icons.person_rounded,
                      size: 68,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colors.primary,
            shape: BoxShape.circle,
            border: Border.all(
              color: colors.surface,
              width: 3,
            ),
          ),
          child: IconButton(
            onPressed: _isPickingImage || _isBusy
                ? null
                : _pickImage,
            tooltip: 'Cambiar fotografía',
            padding: EdgeInsets.zero,
            icon: _isPickingImage
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.camera_alt_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
          ),
        ),
      ],
    );
  }



  Widget _buildProfileHeader() {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          _buildProfileImage(),
          const SizedBox(height: 17),
          Text(
            _nameController.text.isEmpty
                ? 'Mi cuenta'
                : _nameController.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _email,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onPrimaryContainer,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: colors.primary,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  'Cuenta personal',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: colors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            tooltip: 'Preferencias de notificaciones',
            icon: const Icon(
              Icons.notifications_outlined,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _isLoadingProfile
          ? Center(
              child: CircularProgressIndicator(
                color: colors.primary,
              ),
            )
          : _userId == null
              ? Center(
                  child: Text(
                    'No existe una sesión activa.',
                    style: TextStyle(
                      color: colors.onSurface,
                    ),
                  ),
                )
              : AbsorbPointer(
                  absorbing: _isBusy || _isPickingImage,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      18,
                      18,
                      35,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          _buildProfileHeader(),

                          const SizedBox(height: 25),

                          _buildSectionTitle(
                            context,
                            'Información personal',
                            'Administra los datos de tu cuenta.',
                            Icons.person_outline_rounded,
                          ),

                          const SizedBox(height: 17),

                          Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(17),
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _nameController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: const InputDecoration(
                                      labelText: 'Nombre completo',
                                      hintText: 'Escribe tu nombre',
                                      prefixIcon: Icon(
                                        Icons.person_outline_rounded,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'El nombre es obligatorio.';
                                      }

                                      if (value.trim().length < 2) {
                                        return 'Ingresa al menos 2 caracteres.';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 18),

                                  TextFormField(
                                    initialValue: _email,
                                    readOnly: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Correo electrónico',
                                      prefixIcon: Icon(
                                        Icons.email_outlined,
                                      ),
                                      helperText:
                                          'Correo vinculado a tu cuenta.',
                                    ),
                                  ),

                                  const SizedBox(height: 18),

                                  TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    maxLength: 10,
                                    decoration: const InputDecoration(
                                      labelText: 'Teléfono',
                                      hintText: '2281234567',
                                      prefixIcon: Icon(
                                        Icons.phone_outlined,
                                      ),
                                      counterText: '',
                                      helperText:
                                          'Ingresa un número de 10 dígitos.',
                                    ),
                                    validator: (value) {
                                      final phone =
                                          value?.replaceAll(
                                                RegExp(r'\D'),
                                                '',
                                              ) ??
                                              '';

                                      if (phone.isEmpty) {
                                        return 'El teléfono es obligatorio.';
                                      }

                                      if (!RegExp(r'^\d{10}$')
                                          .hasMatch(phone)) {
                                        return 'Ingresa un teléfono de 10 dígitos.';
                                      }

                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            height: 53,
                            child: ElevatedButton.icon(
                              onPressed: _isBusy
                                  ? null
                                  : _saveProfile,
                              icon: _isSaving
                                  ? const SizedBox(
                                      height: 19,
                                      width: 19,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.save_outlined,
                                    ),
                              label: Text(
                                _isSaving
                                    ? 'Guardando cambios...'
                                    : 'Guardar cambios',
                              ),
                            ),
                          ),

                          const SizedBox(height: 31),

                          Divider(
                            color: colors.outline.withValues(
                              alpha: 0.4,
                            ),
                          ),

                          const SizedBox(height: 20),

                          _buildSectionTitle(
                            context,
                            'Administración de cuenta',
                            'Opciones permanentes de tu usuario.',
                            Icons.manage_accounts_outlined,
                          ),

                          const SizedBox(height: 15),

                          Container(
                            padding: const EdgeInsets.all(17),
                            decoration: BoxDecoration(
                              color: colors.errorContainer,
                              borderRadius: BorderRadius.circular(19),
                              border: Border.all(
                                color: colors.error.withValues(
                                  alpha: 0.15,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: colors.error,
                                  size: 26,
                                ),
                                const SizedBox(height: 11),
                                Text(
                                  'Zona de eliminación',
                                  style: TextStyle(
                                    color: colors.error,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Eliminar tu cuenta borrará tu usuario '
                                  'de Firebase y los datos locales de este perfil. '
                                  'Esta acción no se puede deshacer.',
                                  style: TextStyle(
                                    color: colors.onErrorContainer,
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 17),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _isBusy
                                        ? null
                                        : _confirmDeleteAccount,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: colors.error,
                                      side: BorderSide(
                                        color: colors.error,
                                      ),
                                      backgroundColor: colors.surface,
                                    ),
                                    icon: _isDeleting
                                        ? const SizedBox(
                                            height: 17,
                                            width: 17,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.delete_forever_rounded,
                                          ),
                                    label: Text(
                                      _isDeleting
                                          ? 'Eliminando cuenta...'
                                          : 'Eliminar mi cuenta',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
