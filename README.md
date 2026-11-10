\# Noticias App – Fase 3



\*\*Aplicación móvil de noticias desarrollada con Flutter, WordPress REST API y Firebase.\*\*



Noticias App permite consultar noticias de actualidad, buscar publicaciones, filtrar por categorías, guardar favoritos, comentar artículos y recibir notificaciones personalizadas. Incorpora autenticación de usuarios, gestión de perfil, temas claro y oscuro y almacenamiento local para consultar noticias previamente cargadas sin conexión.



\## 1. Información del proyecto



| Dato | Valor |

|---|---|

| Nombre | Noticias App |

| Versión | 1.0.0+1 |

| Framework | Flutter |

| Lenguaje | Dart |

| Identificador Android | `com.example.noticias\_app` |

| Proyecto Firebase | `noticias-app-82025` |

| API de noticias | WordPress REST API |



\## 2. Tecnologías y dependencias



\*\*Desarrollo móvil\*\*

\- Flutter y Dart.

\- Material Design 3.

\- Provider para la administración del estado.



\*\*Conexión y almacenamiento\*\*

\- HTTP para las solicitudes a WordPress.

\- SharedPreferences para preferencias, favoritos y caché local.

\- connectivity\_plus para detectar cambios de conectividad.



\*\*Servicios de Firebase\*\*

\- Firebase Authentication para el inicio de sesión.

\- Cloud Firestore para los comentarios.

\- Firebase Cloud Messaging (FCM) para las notificaciones push.



\*\*Otros componentes\*\*

\- flutter\_html para mostrar el contenido de WordPress.

\- image\_picker para seleccionar fotografías de perfil.

\- path\_provider para gestionar archivos locales.

\- flutter\_lints y flutter\_test para análisis y pruebas.



\## 3. Funcionalidades implementadas



\### Noticias

\- Consulta de noticias recientes desde WordPress.

\- Visualización del detalle de cada publicación.

\- Búsqueda por palabras clave.

\- Filtrado por categorías.

\- Paginación y carga progresiva.

\- Actualización mediante gesto de desplazamiento.



\### Favoritos

\- Guardado de noticias mediante bookmarks.

\- Persistencia local de los identificadores.

\- Consulta y eliminación de noticias guardadas.



\### Personalización

\- Tema claro y tema oscuro.

\- Interfaz moderna con tonos lavanda.

\- Preferencia de apariencia persistente.

\- Transiciones y animaciones en componentes.



\### Autenticación y perfil

\- Inicio de sesión mediante Firebase Authentication.

\- Persistencia de sesión.

\- Pantallas de bienvenida y acceso.

\- Edición del nombre y teléfono.

\- Selección y almacenamiento local de fotografía de perfil.

\- Eliminación de cuenta con confirmación de identidad.



\### Comentarios

\- Publicación de comentarios asociados a noticias.

\- Almacenamiento en Cloud Firestore.

\- Edición y eliminación de comentarios propios.

\- Restricción de operaciones según el usuario autenticado.

\- Indicadores de carga y mensajes de error.



\### Notificaciones

\- Integración con Firebase Cloud Messaging.

\- Solicitud de permisos.

\- Preferencias de suscripción por categorías.

\- Recepción de mensajes.

\- Gestión de suscripciones a temas de notificación.



\### Funcionamiento sin conexión

\- Detección de cambios de conectividad.

\- Almacenamiento local de noticias y categorías.

\- Recuperación de información previamente almacenada.

\- Conservación de hasta 30 noticias por consulta de caché.

\- Sincronización al recuperar la conexión.

\- Indicadores visuales del estado de conexión.



\### Estados de la aplicación

\- Carga.

\- Contenido disponible.

\- Resultado vacío.

\- Errores de conexión y recuperación.



\## 4. Estructura del proyecto



```text

noticias\_app/

│

├── android/

├── ios/

├── linux/

├── macos/

├── web/

├── windows/

│

├── lib/

│   ├── components/

│   │   ├── comment\_card.dart

│   │   └── news\_card.dart

│   │

│   ├── models/

│   │   ├── category\_model.dart

│   │   ├── comment\_model.dart

│   │   └── news\_model.dart

│   │

│   ├── providers/

│   │   ├── app\_provider.dart

│   │   ├── auth\_provider.dart

│   │   ├── bookmark\_provider.dart

│   │   ├── comment\_provider.dart

│   │   ├── news\_provider.dart

│   │   └── notification\_provider.dart

│   │

│   ├── screens/

│   │   ├── bookmarks\_screen.dart

│   │   ├── home\_screen.dart

│   │   ├── login\_screen.dart

│   │   ├── news\_detail\_screen.dart

│   │   ├── onboarding\_screen.dart

│   │   ├── profile\_screen.dart

│   │   ├── settings\_screen.dart

│   │   └── splash\_screen.dart

│   │

│   ├── services/

│   │   ├── auth\_service.dart

│   │   ├── bookmark\_service.dart

│   │   ├── cache\_service.dart

│   │   ├── comment\_service.dart

│   │   ├── news\_service.dart

│   │   ├── notification\_service.dart

│   │   └── user\_service.dart

│   │

│   ├── app\_theme.dart

│   ├── firebase\_options.dart

│   └── main.dart

│

├── test/

│   ├── providers/

│   │   └── news\_provider\_test.dart

│   ├── services/

│   │   └── cache\_service\_test.dart

│   └── widget\_test.dart

│

├── analysis\_options.yaml

├── firebase.json

├── pubspec.yaml

├── pubspec.lock

└── README.md

```



\## 5. Requisitos para ejecutar el proyecto



Se necesita:



\- Flutter SDK compatible con la restricción de Dart del proyecto (`^3.13.5`).

\- Dart SDK.

\- Android Studio.

\- Android SDK y un emulador o dispositivo Android.

\- Cuenta y proyecto de Firebase.

\- Acceso a Internet para consultar WordPress y los servicios remotos.



Para comprobar las herramientas instaladas:



```bash

flutter doctor -v

flutter --version

dart --version

```



\## 6. Instalación



Clonar el repositorio:



```bash

git clone https://github.com/yenifermtnezhdez-ops/noticias\_app.git

```



Entrar en el proyecto:



```bash

cd noticias\_app

```



Instalar las dependencias:



```bash

flutter pub get

```



Ejecutar el análisis:



```bash

flutter analyze

```



Ejecutar las pruebas automatizadas:



```bash

flutter test

```



Iniciar la aplicación:



```bash

flutter run

```



\## 7. Configuración de WordPress



La aplicación consume la API REST de WordPress.



\*\*Endpoint de publicaciones:\*\*



```text

https://news.freepi.io/wp-json/wp/v2/posts

```



\*\*Endpoint de categorías:\*\*



```text

https://news.freepi.io/wp-json/wp/v2/categories

```



No se requiere una contraseña de WordPress para consultar los endpoints públicos utilizados por la aplicación.



La disponibilidad de las noticias depende del servicio remoto y de la conexión a Internet.



\## 8. Configuración de Firebase



El proyecto utiliza el identificador Firebase:



```text

noticias-app-82025

```



El identificador Android configurado es:



```text

com.example.noticias\_app

```



Para ejecutar el proyecto con otro entorno de Firebase:



1\. Crear o seleccionar un proyecto en Firebase Console.

2\. Registrar una aplicación Android utilizando el identificador `com.example.noticias\_app`, o el identificador que se configure posteriormente en Android.

3\. Descargar el archivo `google-services.json`.

4\. Colocarlo dentro de `android/app/`.

5\. Configurar Firebase para Flutter y generar `lib/firebase\_options.dart` mediante FlutterFire CLI.

6\. Habilitar Email/Password en Firebase Authentication.

7\. Crear Cloud Firestore y publicar reglas de seguridad apropiadas.

8\. Configurar Firebase Cloud Messaging.

9\. Verificar los permisos de notificaciones en Android.



Para generar nuevamente la configuración de FlutterFire puede utilizarse:



```bash

dart pub global activate flutterfire\_cli

flutterfire configure

```



\### Seguridad de Firebase



Las reglas de Firestore deben restringir las operaciones de escritura, edición y eliminación de comentarios a usuarios autenticados y propietarios de cada comentario.



No debe utilizarse el modo de prueba de Firestore en una entrega de producción.



Los archivos de configuración cliente de Firebase permiten identificar la aplicación y conectarla al proyecto; no sustituyen las reglas de seguridad.



\*\*Nunca incluir en el repositorio:\*\*

\- Archivos de cuentas de servicio de Firebase.

\- Contraseñas.

\- Tokens privados.

\- Claves de firma de Android.

\- Archivos `.env` con credenciales.

\- Claves privadas o certificados de acceso.



Los envíos administrativos de notificaciones deben realizarse desde un entorno seguro de servidor, nunca exponiendo una clave privada dentro de la aplicación.



\## 9. Notificaciones por categorías



La aplicación administra las suscripciones mediante temas de Firebase Cloud Messaging.



El formato utilizado es:



```text

noticias\_categoria\_ID

```



Cada usuario puede modificar sus preferencias desde la pantalla de configuración.



Las notificaciones requieren permisos del dispositivo y una conexión adecuada a los servicios de Firebase.



\## 10. Pruebas automatizadas



Para ejecutar todas las pruebas:



```bash

flutter test

```



Los archivos de pruebas cubren:



\- Inicio de la pantalla principal.

\- Guardado y recuperación de noticias en caché.

\- Guardado y recuperación de categorías.

\- Eliminación de datos almacenados.

\- Prevención de identificadores duplicados.

\- Límite de noticias almacenadas.

\- Cambios de estado de conexión.

\- Generación de claves de caché.

\- Separación de caché por búsqueda y categoría.



Para analizar el código:



```bash

flutter analyze

```



\## 11. Generar el APK de Android



Para compilar una versión de distribución:



```bash

flutter build apk --release

```



El APK se genera en:



```text

build/app/outputs/flutter-apk/app-release.apk

```



Para instalarlo en un dispositivo Android mediante ADB:



```bash

adb install -r build/app/outputs/flutter-apk/app-release.apk

```



La compilación debe ejecutarse después de verificar la configuración de Firebase y las dependencias.



\## 12. Consideraciones y limitaciones



\- Las noticias dependen de la disponibilidad de la API de WordPress.

\- La caché permite consultar contenido previamente almacenado, pero no sustituye la conexión remota.

\- Los comentarios y las notificaciones necesitan conexión con Firebase.

\- La caché conserva un máximo de 30 noticias por consulta.

\- Los favoritos almacenan localmente los identificadores de las publicaciones.

\- Para ejecutar Firebase en otra aplicación o plataforma puede ser necesaria una configuración adicional.

\- La configuración de Android está asociada al identificador `com.example.noticias\_app`.

\- El proyecto debe probarse en el dispositivo de destino antes de considerarse una compilación final de distribución.



\## 13. Evidencias de entrega



Se recomienda acompañar el código fuente con capturas de pantalla o grabaciones que demuestren:



1\. Splash y Onboarding.

2\. Inicio de sesión.

3\. Pantalla principal con noticias.

4\. Búsqueda y filtros por categorías.

5\. Detalle de una noticia.

6\. Guardado de favoritos.

7\. Publicación, edición y eliminación de comentarios propios.

8\. Edición del perfil.

9\. Preferencias de notificaciones.

10\. Funcionamiento sin conexión.

11\. Cambio entre tema claro y oscuro.

12\. Cierre de sesión.



\## 14. Autoría y propósito académico



Proyecto desarrollado como parte de la Fase 3 del curso App Lab.



\*\*Resultado:\*\* aplicación móvil de noticias que integra una API REST real, autenticación, almacenamiento remoto y local, comentarios, notificaciones push y manejo de conectividad mediante Flutter.



\---



\*\*Noticias App – Fase 3\*\*  

\*Mantente informado.\*



