
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

class NotificationService {
  final FirebaseMessaging _messaging;

  NotificationService({
    FirebaseMessaging? messaging,
  }) : _messaging = messaging ?? FirebaseMessaging.instance;

  // Solicitar permisos para recibir notificaciones.
  Future<NotificationSettings> requestPermission() async {
    return await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  // Consultar el estado actual de los permisos.
  Future<NotificationSettings> getNotificationSettings() async {
    return await _messaging.getNotificationSettings();
  }

  // Registrar el dispositivo en Firebase Cloud Messaging.
  Future<void> registerDevice() async {
    await _messaging.register();
  }

  // Escuchar el Firebase Installation ID (FID).
  // Esta API sustituye al token tradicional en la API nueva.
  Stream<String> get onRegistered {
    return _messaging.onRegistered;
  }

  // Escuchar mensajes recibidos con la aplicación abierta.
  Stream<RemoteMessage> get onMessage {
    return FirebaseMessaging.onMessage;
  }

  // Escuchar cuando el usuario toca una notificación.
  Stream<RemoteMessage> get onMessageOpenedApp {
    return FirebaseMessaging.onMessageOpenedApp;
  }

  // Obtener el mensaje que abrió la aplicación.
  Future<RemoteMessage?> getInitialMessage() async {
    return await _messaging.getInitialMessage();
  }

  // Suscribirse al tópico de una categoría.
  Future<void> subscribeToCategory(int categoryId) async {
    final topic = topicForCategory(categoryId);

    await _messaging.subscribeToTopic(topic);
  }

  // Cancelar la suscripción a una categoría.
  Future<void> unsubscribeFromCategory(int categoryId) async {
    final topic = topicForCategory(categoryId);

    await _messaging.unsubscribeFromTopic(topic);
  }

  // Crear identificadores únicos y estables.
  static String topicForCategory(int categoryId) {
    if (categoryId <= 0) {
      throw ArgumentError(
        'El ID de categoría debe ser positivo.',
      );
    }

    return 'noticias_categoria_$categoryId';
  }

  // Configurar la presentación en primer plano
  // para plataformas Apple.
  Future<void> configureForegroundPresentation() async {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }
}

// Manejador de mensajes en segundo plano.
// Debe permanecer como función de nivel superior.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint(
    'Mensaje recibido en segundo plano: ${message.messageId}',
  );
}
