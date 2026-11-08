
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app_theme.dart';
import 'firebase_options.dart';

import 'providers/app_provider.dart';
import 'providers/bookmark_provider.dart';
import 'providers/auth_provider.dart';

import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final appProvider = AppProvider();
  await appProvider.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppProvider>.value(
          value: appProvider,
        ),
        ChangeNotifierProvider<BookmarkProvider>(
          create: (_) =>
              BookmarkProvider()..loadBookmarks(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
      ],
      child: const NoticiasApp(),
    ),
  );
}

class NoticiasApp extends StatelessWidget {
  const NoticiasApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Noticias App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appProvider.themeMode,
      themeAnimationDuration:
          const Duration(milliseconds: 350),

      themeAnimationCurve: Curves.easeInOut,
      home: const SplashScreen(),
    );
  }
}
