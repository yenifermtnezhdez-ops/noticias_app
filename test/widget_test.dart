
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:noticias_app/models/news_model.dart';
import 'package:noticias_app/models/category_model.dart';

import 'package:noticias_app/screens/home_screen.dart';

import 'package:noticias_app/services/news_service.dart';

import 'package:noticias_app/providers/app_provider.dart';
import 'package:noticias_app/providers/bookmark_provider.dart';
import 'package:noticias_app/providers/news_provider.dart';

import 'package:noticias_app/app_theme.dart';


class FakeNewsService extends NewsService {
  @override
  Future<List<NewsModel>> getNews({
    int page = 1,
    int perPage = 10,
  }) async {
    return [];
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    return [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'La pantalla de noticias inicia correctamente',
    (WidgetTester tester) async {
    
      SharedPreferences.setMockInitialValues({});


      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppProvider>(
              create: (_) => AppProvider(),
            ),
            ChangeNotifierProvider<BookmarkProvider>(
              create: (_) => BookmarkProvider(),
            ),
            ChangeNotifierProvider<NewsProvider>(
          
              create: (_) => NewsProvider(),
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: HomeScreen(
              newsService: FakeNewsService(),
            ),
          ),
        ),
      );

    
      await tester.pumpAndSettle();

     
      expect(
        find.text('Noticias App'),
        findsOneWidget,
      );

     
      expect(
        find.text(
          'No hay noticias disponibles para esta selección.',
        ),
        findsOneWidget,
      );
    },
  );
}
