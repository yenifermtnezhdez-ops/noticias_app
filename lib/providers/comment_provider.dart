
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/comment_model.dart';
import '../services/comment_service.dart';

class CommentProvider extends ChangeNotifier {
  final CommentService _commentService;
  final int _newsId;

  StreamSubscription<List<CommentModel>>? _subscription;

  List<CommentModel> _comments = [];

  bool _isLoading = true;
  bool _isWriting = false;

  String? _errorMessage;

  CommentProvider({
    required int newsId,
    CommentService? commentService,
  })  : _newsId = newsId,
        _commentService = commentService ?? CommentService() {
    _listenToComments();
  }


  List<CommentModel> get comments =>
      List.unmodifiable(_comments);


  bool get isLoading => _isLoading;

  bool get isWriting => _isWriting;


  String? get errorMessage => _errorMessage;

  
  int get commentCount => _comments.length;

  
  void _listenToComments() {
    _subscription = _commentService
        .watchComments(_newsId)
        .listen(
      (comments) {
        _comments = comments;
        _isLoading = false;
        _errorMessage = null;

        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error al consultar comentarios: $error');

        _isLoading = false;
        _errorMessage =
            'No fue posible cargar los comentarios.';

        notifyListeners();
      },
    );
  }

  
  Future<bool> addComment({
    required String content,
    required String userName,
  }) async {
    final text = content.trim();

    if (text.isEmpty) {
      _errorMessage = 'El comentario no puede estar vacío.';
      notifyListeners();
      return false;
    }

    if (_isWriting) return false;

    _isWriting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _commentService.addComment(
        newsId: _newsId,
        content: text,
        userName: userName,
      );

      return true;
    } catch (e) {
      debugPrint('Error al publicar comentario: $e');

      _errorMessage = _getErrorMessage(e);

      return false;
    } finally {
      _isWriting = false;
      notifyListeners();
    }
  }

 
  Future<bool> updateComment({
    required String commentId,
    required String content,
  }) async {
    final text = content.trim();

    if (text.isEmpty) {
      _errorMessage = 'El comentario no puede estar vacío.';
      notifyListeners();
      return false;
    }

    if (_isWriting) return false;

    _isWriting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _commentService.updateComment(
        newsId: _newsId,
        commentId: commentId,
        content: text,
      );

      return true;
    } catch (e) {
      debugPrint('Error al editar comentario: $e');

      _errorMessage = _getErrorMessage(e);

      return false;
    } finally {
      _isWriting = false;
      notifyListeners();
    }
  }


  Future<bool> deleteComment({
    required String commentId,
  }) async {
    if (_isWriting) return false;

    _isWriting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _commentService.deleteComment(
        newsId: _newsId,
        commentId: commentId,
      );

      return true;
    } catch (e) {
      debugPrint('Error al eliminar comentario: $e');

      _errorMessage = _getErrorMessage(e);

      return false;
    } finally {
      _isWriting = false;
      notifyListeners();
    }
  }

  
  String _getErrorMessage(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'No tienes permiso para realizar esta acción.';

        case 'unavailable':
          return 'No hay conexión con el servidor.';

        case 'not-found':
          return 'El comentario ya no existe.';

        default:
          return 'No fue posible completar la operación.';
      }
    }

    final message = error
        .toString()
        .replaceFirst('Exception: ', '');

    return message.isEmpty
        ? 'Ocurrió un error. Intenta nuevamente.'
        : message;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
