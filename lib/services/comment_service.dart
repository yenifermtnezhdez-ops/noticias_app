
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/comment_model.dart';

class CommentService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CommentService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  
  CollectionReference<Map<String, dynamic>> _commentsCollection(
    int newsId,
  ) {
    return _firestore
        .collection('news')
        .doc(newsId.toString())
        .collection('comments');
  }

  
  Stream<List<CommentModel>> watchComments(int newsId) {
    return _commentsCollection(newsId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(CommentModel.fromFirestore)
          .toList();
    });
  }

 
  Future<void> addComment({
    required int newsId,
    required String content,
    required String userName,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Debes iniciar sesión para publicar comentarios.',
      );
    }

    final text = content.trim();

    if (text.isEmpty) {
      throw Exception('El comentario no puede estar vacío.');
    }

    if (text.length > 1000) {
      throw Exception(
        'El comentario no puede superar los 1000 caracteres.',
      );
    }

    final comment = {
      'newsId': newsId,
      'userId': user.uid,
      'userName': userName.trim().isEmpty
          ? user.email ?? 'Usuario'
          : userName.trim(),
      'content': text,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _commentsCollection(newsId).add(comment);
  }

  
  Future<void> updateComment({
    required int newsId,
    required String commentId,
    required String content,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Debes iniciar sesión para editar comentarios.',
      );
    }

    final text = content.trim();

    if (text.isEmpty) {
      throw Exception('El comentario no puede estar vacío.');
    }

    if (text.length > 1000) {
      throw Exception(
        'El comentario no puede superar los 1000 caracteres.',
      );
    }

    final reference = _commentsCollection(newsId).doc(commentId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

      if (!snapshot.exists) {
        throw Exception('El comentario ya no existe.');
      }

      final data = snapshot.data()!;

      if (data['userId'] != user.uid) {
        throw Exception(
          'No tienes permiso para editar este comentario.',
        );
      }

      transaction.update(reference, {
        'content': text,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  
  Future<void> deleteComment({
    required int newsId,
    required String commentId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Debes iniciar sesión para eliminar comentarios.',
      );
    }

    final reference = _commentsCollection(newsId).doc(commentId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

      if (!snapshot.exists) {
        throw Exception('El comentario ya no existe.');
      }

      final data = snapshot.data()!;

      if (data['userId'] != user.uid) {
        throw Exception(
          'No tienes permiso para eliminar este comentario.',
        );
      }

      transaction.delete(reference);
    });
  }
}
