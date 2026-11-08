
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;

  AuthService({
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges();
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
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
