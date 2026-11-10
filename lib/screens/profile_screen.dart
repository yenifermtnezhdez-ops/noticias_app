
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import '../screens/settings_screen.dart';



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

  bool _isLoadingProfile = true;
  bool _isSaving = false;
  bool _isPickingImage = false;
  bool _isDeleting = false;

  String _email = '';
  String? _userId;

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
    if (_userId == null || _isPickingImage) return;

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
    final passwordController = TextEditingController();
    final passwordFormKey = GlobalKey<FormState>();

    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar cuenta'),
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
                    prefixIcon: Icon(Icons.lock_outline),
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
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

    if (userId == null) return;

    setState(() {
      _isDeleting = true;
    });

    final success = await authProvider.deleteAccount(
      password: password,
    );

    if (!success) {
      if (!mounted) return;

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
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? Theme.of(context).colorScheme.error
              : Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
  }
  Widget _buildProfileImage() {
    final colors = Theme.of(context).colorScheme;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 125,
          height: 125,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.primaryContainer,
            border: Border.all(
              color: colors.primary,
              width: 3,
            ),
          ),
          child: ClipOval(
            child: _imagePath != null &&
                    File(_imagePath!).existsSync()
                ? Image.file(
                    File(_imagePath!),
                    fit: BoxFit.cover,
                   errorBuilder: (_, _, _) {
                      return Icon(
                        Icons.person,
                        size: 70,
                        color: colors.onPrimaryContainer,
                      );
                    },
                  )
                : Icon(
                    Icons.person,
                    size: 70,
                    color: colors.onPrimaryContainer,
                  ),
          ),
        ),
        CircleAvatar(
          radius: 21,
          backgroundColor: colors.primary,
          child: IconButton(
            onPressed:
                _isPickingImage || _isSaving || _isDeleting
                    ? null
                    : _pickImage,
            tooltip: 'Cambiar fotografía',
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
                    Icons.camera_alt,
                    size: 19,
                    color: Colors.white,
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final isBusy = _isSaving || _isDeleting;

    return Scaffold(
      appBar: AppBar(
  title: const Text('Mi perfil'),
  actions: [
    IconButton(
      tooltip: 'Preferencias de notificaciones',
      icon: const Icon(Icons.notifications_outlined),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SettingsScreen(),
          ),
        );
      },
    ),
  ],
),
      body: _isLoadingProfile
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _userId == null
              ? const Center(
                  child: Text(
                    'No existe una sesión activa.',
                  ),
                )
              : AbsorbPointer(
                  absorbing: isBusy || _isPickingImage,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 15),
                          Center(
                            child: _buildProfileImage(),
                          ),

                          const SizedBox(height: 18),

                          Text(
                            'Información personal',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Administra los datos de tu cuenta.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                            ),
                          ),

                          const SizedBox(height: 32),
                          const Text(
                            'Nombre completo',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 8),

                          TextFormField(
                            controller: _nameController,
                            textCapitalization:
                                TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'Tu nombre',
                              prefixIcon: Icon(
                                Icons.person_outline,
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

                          const SizedBox(height: 22),
                          const Text(
                            'Correo electrónico',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 8),

                          TextFormField(
                            initialValue: _email,
                            readOnly: true,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(
                                Icons.email_outlined,
                              ),
                              helperText:
                                  'El correo está vinculado a tu autenticación.',
                            ),
                          ),

                          const SizedBox(height: 22),
                          const Text(
                            'Teléfono',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 8),

                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            decoration: const InputDecoration(
                              hintText: 'Ej. 2281234567',
                              prefixIcon: Icon(
                                Icons.phone_outlined,
                              ),
                              counterText: '',
                              helperText:
                                  'Ingresa 10 dígitos.',
                            ),
                            validator: (value) {
                              final phone = value?.replaceAll(
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

                          const SizedBox(height: 30),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: isBusy
                                  ? null
                                  : _saveProfile,
                              icon: _isSaving
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(
                                _isSaving
                                    ? 'Guardando...'
                                    : 'Guardar cambios',
                              ),
                            ),
                          ),

                          const SizedBox(height: 35),

                          Divider(
                            color: colors.outlineVariant,
                          ),

                          const SizedBox(height: 20),

                          Text(
                            'Zona de administración',
                            style: TextStyle(
                              color: colors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            'Eliminar tu cuenta borrará tu usuario '
                            'de Firebase y los datos locales de este perfil. '
                            'Esta acción no se puede deshacer.',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 18),

                          OutlinedButton.icon(
                            onPressed: isBusy
                                ? null
                                : _confirmDeleteAccount,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.error,
                              side: BorderSide(
                                color: colors.error,
                              ),
                              padding: const EdgeInsets.all(15),
                            ),
                            icon: _isDeleting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.delete_forever),
                            label: Text(
                              _isDeleting
                                  ? 'Eliminando cuenta...'
                                  : 'Eliminar mi cuenta',
                            ),
                          ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
