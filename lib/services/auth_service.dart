
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;

  AuthService({
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;
  Stream<User?> get userChanges {
    return _firebaseAuth.userChanges();
  }
  User? get currentUser {
    return _firebaseAuth.currentUser;
  }
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }
  Future<void> updateDisplayName({
    required String name,
  }) async {
    final user = currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No existe un usuario autenticado.',
      );
    }

    await user.updateDisplayName(name.trim());
    await user.reload();
  }
  Future<void> deleteAccount({
    required String password,
  }) async {
    final user = currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No existe un usuario autenticado.',
      );
    }

    final email = user.email;

    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-email',
        message: 'No se encontró el correo de la cuenta.',
      );
    }
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await user.reauthenticateWithCredential(credential);
    await user.delete();
  }
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
