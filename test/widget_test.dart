
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noticias_app/models/news_model.dart';
import 'package:noticias_app/models/category_model.dart';
import 'package:noticias_app/screens/home_screen.dart';
import 'package:noticias_app/services/news_service.dart';

class FakeNewsService extends NewsService {
  @override
  Future<List<NewsModel>> getNews() async {
    return [];
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    return [];
  }

}

void main() {
  testWidgets(
    'La pantalla de noticias inicia correctamente',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            newsService: FakeNewsService(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Noticias App'), findsOneWidget);

      expect(
        find.text(
          'No hay noticias disponibles para esta selección.',
        ),
        findsOneWidget,
      );
    },
  );
}
