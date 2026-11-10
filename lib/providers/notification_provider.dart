
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category_model.dart';
import '../services/news_service.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  static const String _subscriptionsKey =
      'notification_category_subscriptions';

  final NotificationService _notificationService;
  final NewsService _newsService;

  List<CategoryModel> _categories = [];

  Set<int> _subscribedCategoryIds = {};

  final Set<int> _pendingCategoryIds = {};

  bool _isLoading = true;
  bool _isRequestingPermission = false;
  bool _isInitialized = false;

  AuthorizationStatus? _authorizationStatus;

  String? _installationId;
  String? _errorMessage;

  RemoteMessage? _lastMessage;
  RemoteMessage? _lastOpenedMessage;

  StreamSubscription<String>? _registrationSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openedMessageSubscription;

  NotificationProvider({
    NotificationService? notificationService,
    NewsService? newsService,
  })  : _notificationService =
            notificationService ?? NotificationService(),
        _newsService = newsService ?? NewsService() {
    _listenToMessages();
  }

  // GETTERS
  List<CategoryModel> get categories =>
      List.unmodifiable(_categories);

  Set<int> get subscribedCategoryIds =>
      Set.unmodifiable(_subscribedCategoryIds);

  Set<int> get pendingCategoryIds =>
      Set.unmodifiable(_pendingCategoryIds);

  bool get isLoading => _isLoading;

  bool get isRequestingPermission =>
      _isRequestingPermission;

  String? get errorMessage => _errorMessage;

  String? get installationId => _installationId;

  RemoteMessage? get lastMessage => _lastMessage;

  RemoteMessage? get lastOpenedMessage =>
      _lastOpenedMessage;

  AuthorizationStatus? get authorizationStatus =>
      _authorizationStatus;

  bool get hasPermission =>
      _authorizationStatus == AuthorizationStatus.authorized ||
      _authorizationStatus == AuthorizationStatus.provisional;

  bool isCategorySubscribed(int categoryId) =>
      _subscribedCategoryIds.contains(categoryId);

  bool isCategoryBusy(int categoryId) =>
      _pendingCategoryIds.contains(categoryId);

  // INICIALIZAR NOTIFICACIONES
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isInitialized = true;
    _isLoading = true;

    notifyListeners();

    // Escuchar el registro de Firebase antes de llamar register().
    _registrationSubscription =
        _notificationService.onRegistered.listen(
      (installationId) {
        _installationId = installationId;

        // IDENTIFICADOR PARA LA PRUEBA EN FIREBASE CONSOLE.
        debugPrint('');
        debugPrint('======================================');
        debugPrint('FCM_FID_PRUEBA: $installationId');
        debugPrint('Dispositivo registrado correctamente.');
        debugPrint('======================================');
        debugPrint('');

        notifyListeners();

        // Restaurar las suscripciones guardadas.
        _restoreSubscriptions();
      },
      onError: (error) {
        debugPrint('ERROR AL REGISTRAR FCM: $error');

        _errorMessage =
            'No fue posible registrar el dispositivo.';

        notifyListeners();
      },
    );

    try {
      // Recuperar preferencias guardadas.
      await _loadSavedSubscriptions();

      // Consultar categorías de WordPress.
      await refreshCategories();

      // Consultar permisos actuales.
      final settings =
          await _notificationService.getNotificationSettings();

      _authorizationStatus = settings.authorizationStatus;

      debugPrint(
        'Estado del permiso de notificaciones: '
        '${_authorizationStatus?.name}',
      );

      // Configurar presentación de notificaciones.
      await _notificationService
          .configureForegroundPresentation();

      // Consultar si una notificación abrió la aplicación.
      final initialMessage =
          await _notificationService.getInitialMessage();

      if (initialMessage != null) {
        _lastOpenedMessage = initialMessage;
        debugPrint('La aplicación fue abierta desde una notificación.');
      }

      // Registrar el dispositivo cuando ya hay autorización.
      if (hasPermission) {
        debugPrint('Iniciando registro del dispositivo en FCM...');

        await _notificationService.registerDevice();

        debugPrint('Solicitud de registro FCM completada.');
      } else {
        debugPrint(
          'El dispositivo todavía no tiene permiso '
          'para recibir notificaciones.',
        );
      }
    } catch (e) {
      debugPrint('Error al inicializar notificaciones: $e');
      _errorMessage = _getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ESCUCHAR MENSAJES
  void _listenToMessages() {
    // Mensajes recibidos con la aplicación abierta.
    _messageSubscription =
        _notificationService.onMessage.listen(
      (message) {
        _lastMessage = message;

        debugPrint('NOTIFICACIÓN RECIBIDA EN PRIMER PLANO');
        debugPrint('Título: ${message.notification?.title}');
        debugPrint('Mensaje: ${message.notification?.body}');
        debugPrint('Datos: ${message.data}');

        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error al recibir mensaje: $error');
      },
    );

    // Mensajes abiertos desde una notificación.
    _openedMessageSubscription =
        _notificationService.onMessageOpenedApp.listen(
      (message) {
        _lastOpenedMessage = message;

        debugPrint('El usuario abrió una notificación.');
        debugPrint('Datos: ${message.data}');

        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error al abrir notificación: $error');
      },
    );
  }

  // CARGAR CATEGORÍAS
  Future<void> refreshCategories() async {
    try {
      _categories = await _newsService.getCategories();

      final validIds = _categories
          .map((category) => category.id)
          .toSet();

      _subscribedCategoryIds =
          _subscribedCategoryIds.intersection(validIds);

      await _saveSubscriptions(_subscribedCategoryIds);

      _errorMessage = null;

      debugPrint(
        'Categorías disponibles para notificaciones: '
        '${_categories.length}',
      );
    } catch (e) {
      debugPrint('Error al cargar categorías: $e');

      _errorMessage =
          'No fue posible cargar las categorías de noticias.';
    }

    notifyListeners();
  }

  // CARGAR PREFERENCIAS GUARDADAS
  Future<void> _loadSavedSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();

    final savedIds =
        prefs.getStringList(_subscriptionsKey) ?? [];

    _subscribedCategoryIds = savedIds
        .map((value) => int.tryParse(value))
        .whereType<int>()
        .where((id) => id > 0)
        .toSet();

    debugPrint(
      'Categorías suscritas recuperadas: '
      '$_subscribedCategoryIds',
    );
  }

  // GUARDAR PREFERENCIAS
  Future<void> _saveSubscriptions(Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();

    final values = ids
        .map((id) => id.toString())
        .toList();

    await prefs.setStringList(
      _subscriptionsKey,
      values,
    );
  }

  // SOLICITAR PERMISOS
  Future<bool> requestPermission() async {
    if (_isRequestingPermission) return false;

    _isRequestingPermission = true;
    _errorMessage = null;

    notifyListeners();

    try {
      debugPrint('Solicitando permiso de notificaciones...');

      final settings =
          await _notificationService.requestPermission();

      _authorizationStatus = settings.authorizationStatus;

      debugPrint(
        'Resultado del permiso: '
        '${_authorizationStatus?.name}',
      );

      if (!hasPermission) {
        _errorMessage =
            'No se concedió permiso para recibir notificaciones.';

        return false;
      }

      debugPrint('Registrando dispositivo en Firebase Messaging...');

      await _notificationService.registerDevice();

      debugPrint('Registro FCM solicitado correctamente.');

      _errorMessage = null;

      return true;
    } catch (e) {
      debugPrint('Error al solicitar permisos: $e');

      _errorMessage = _getErrorMessage(e);

      return false;
    } finally {
      _isRequestingPermission = false;
      notifyListeners();
    }
  }

  // SUSCRIBIRSE O CANCELAR UNA CATEGORÍA
  Future<bool> setCategoryEnabled(
    CategoryModel category,
    bool enabled,
  ) async {
    final categoryId = category.id;

    if (categoryId <= 0 ||
        isCategoryBusy(categoryId)) {
      return false;
    }

    final alreadySubscribed =
        isCategorySubscribed(categoryId);

    if (alreadySubscribed == enabled) {
      return true;
    }

    _pendingCategoryIds.add(categoryId);
    _errorMessage = null;

    notifyListeners();

    try {
      // Solicitar permiso antes de suscribirse.
      if (enabled && !hasPermission) {
        final permissionGranted =
            await requestPermission();

        if (!permissionGranted) {
          return false;
        }
      }

      final topic =
          NotificationService.topicForCategory(categoryId);

      debugPrint('Actualizando tópico: $topic');

      if (enabled) {
        await _notificationService.subscribeToCategory(
          categoryId,
        );
      } else {
        await _notificationService.unsubscribeFromCategory(
          categoryId,
        );
      }

      // Actualizar estado únicamente después de Firebase.
      final updatedIds =
          Set<int>.from(_subscribedCategoryIds);

      if (enabled) {
        updatedIds.add(categoryId);
      } else {
        updatedIds.remove(categoryId);
      }

      // Guardar preferencias.
      try {
        await _saveSubscriptions(updatedIds);
      } catch (_) {
        // Revertir el cambio si falla el guardado local.
        if (enabled) {
          await _notificationService.unsubscribeFromCategory(
            categoryId,
          );
        } else {
          await _notificationService.subscribeToCategory(
            categoryId,
          );
        }

        rethrow;
      }

      _subscribedCategoryIds = updatedIds;

      _errorMessage = null;

      debugPrint(
        enabled
            ? 'Suscripción completada: $topic'
            : 'Suscripción cancelada: $topic',
      );

      return true;
    } catch (e) {
      debugPrint(
        'Error al actualizar la suscripción: $e',
      );

      _errorMessage = _getErrorMessage(e);

      return false;
    } finally {
      _pendingCategoryIds.remove(categoryId);
      notifyListeners();
    }
  }

  // RESTAURAR SUSCRIPCIONES
  Future<void> _restoreSubscriptions() async {
    if (_subscribedCategoryIds.isEmpty) {
      debugPrint('No hay tópicos guardados para restaurar.');
      return;
    }

    debugPrint('Restaurando suscripciones de categorías...');

    for (final categoryId
        in _subscribedCategoryIds.toList()) {
      try {
        await _notificationService.subscribeToCategory(
          categoryId,
        );

        debugPrint(
          'Tópico restaurado: '
          'noticias_categoria_$categoryId',
        );
      } catch (e) {
        debugPrint(
          'Error al restaurar tópico $categoryId: $e',
        );

        _errorMessage =
            'No fue posible restaurar todas las suscripciones.';

        notifyListeners();
      }
    }
  }

  // LIMPIAR ÚLTIMO MENSAJE
  void clearLastMessage() {
    _lastMessage = null;
    notifyListeners();
  }

  // MENSAJES DE ERROR
  String _getErrorMessage(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'No tienes permisos para esta operación.';

        case 'unavailable':
          return 'No hay conexión con Firebase.';

        case 'network-request-failed':
          return 'Verifica tu conexión a internet.';

        default:
          return 'Firebase no pudo completar la operación.';
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
    _registrationSubscription?.cancel();
    _messageSubscription?.cancel();
    _openedMessageSubscription?.cancel();

    super.dispose();
  }
}
