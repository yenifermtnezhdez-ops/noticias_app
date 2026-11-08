
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  User? _user;

  bool _isLoading = true;

  String? _errorMessage;

  StreamSubscription<User?>? _authSubscription;

  AuthProvider({
    AuthService? authService,
  }) : _authService = authService ?? AuthService() {
    // Escucha cambios de sesión y modificaciones del perfil.
    _authSubscription = _authService.userChanges.listen(
      (User? user) {
        _user = user;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage =
            'No fue posible comprobar tu sesión.';

        debugPrint('Error de autenticación: $error');
        notifyListeners();
      },
    );
  }

  User? get user => _user;
  String get displayName => _user?.displayName ?? '';
  String get email => _user?.email ?? '';
  String? get userId => _user?.uid;
  bool get isAuthenticated => _user != null;

  bool get isLoading => _isLoading;


  String? get errorMessage => _errorMessage;

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authService.signIn(
        email: email,
        password: password,
      );

      _user = credential.user;
      _isLoading = false;
      notifyListeners();

      return _user != null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Error al iniciar sesión: $e');

      _errorMessage =
          'Ocurrió un problema. Intenta nuevamente.';

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDisplayName({
    required String name,
  }) async {
    if (name.trim().isEmpty) {
      _errorMessage = 'El nombre no puede estar vacío.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.updateDisplayName(name: name);

      _user = _authService.currentUser;

      _isLoading = false;
      notifyListeners();

      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Error al actualizar el nombre: $e');

      _errorMessage =
          'No fue posible actualizar el nombre.';

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount({
    required String password,
  }) async {
    if (password.isEmpty) {
      _errorMessage = 'Ingresa tu contraseña.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.deleteAccount(
        password: password,
      );

      _user = null;
      _isLoading = false;
      notifyListeners();

      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Error al eliminar la cuenta: $e');

      _errorMessage =
          'No fue posible eliminar la cuenta.';

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }


  Future<bool> signOut() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signOut();

      _user = null;
      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');

      _errorMessage =
          'No fue posible cerrar la sesión.';

      _isLoading = false;
      notifyListeners();

      return false;
    }
  }


  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No encontramos una cuenta con ese correo.';

      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'El correo o la contraseña son incorrectos.';

      case 'invalid-email':
        return 'Ingresa un correo electrónico válido.';

      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';

      case 'too-many-requests':
        return 'Demasiados intentos. Inténtalo más tarde.';

      case 'network-request-failed':
        return 'No hay conexión. Comprueba tu internet.';

      case 'operation-not-allowed':
        return 'Esta operación no está habilitada.';

      case 'requires-recent-login':
        return 'Debes volver a iniciar sesión para realizar esta acción.';

      case 'weak-password':
        return 'La contraseña no cumple los requisitos.';

      case 'no-current-user':
        return 'No existe un usuario autenticado.';

      case 'missing-email':
        return 'No se encontró el correo de la cuenta.';

      default:
        return 'No fue posible completar la operación.';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
