
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/news_model.dart';
import '../models/category_model.dart';

class NewsService {
  static const String baseUrl =
      'https://news.freepi.io/wp-json/wp/v2/posts';

  static const String categoriesUrl =
      'https://news.freepi.io/wp-json/wp/v2/categories';

  // Convierte el JSON de noticias en modelos.
  List<NewsModel> _parseNews(String responseBody) {
    final List<dynamic> data = jsonDecode(responseBody);

    return data
        .map(
          (item) => NewsModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }
  Future<List<NewsModel>> getNews() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
      );

      if (response.statusCode == 200) {
        final news = _parseNews(response.body);

        print('Conexión exitosa con WordPress');
        print('Noticias recibidas: ${news.length}');

        return news;
      } else {
        throw Exception(
          'Error al obtener noticias: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error de conexión: $e');
      rethrow;
    }
  }
  Future<List<NewsModel>> searchNews(String query) async {
    try {
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'search': query.trim(),
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final news = _parseNews(response.body);

        print('Búsqueda realizada: $query');
        print('Resultados encontrados: ${news.length}');

        return news;
      } else {
        throw Exception(
          'Error al buscar noticias: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error durante la búsqueda: $e');
      rethrow;
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse(categoriesUrl),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final categories = data
            .map(
              (item) => CategoryModel.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();

        print('Categorías recibidas: ${categories.length}');

        return categories;
      } else {
        throw Exception(
          'Error al obtener categorías: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error al consultar categorías: $e');
      rethrow;
    }
  }
  Future<List<NewsModel>> getNewsByCategory(
    int categoryId,
  ) async {
    try {
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'categories': categoryId.toString(),
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final news = _parseNews(response.body);

        print('Categoría seleccionada: $categoryId');
        print('Noticias encontradas: ${news.length}');

        return news;
      } else {
        throw Exception(
          'Error al filtrar noticias: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error al filtrar por categoría: $e');
      rethrow;
    }
  }
}
