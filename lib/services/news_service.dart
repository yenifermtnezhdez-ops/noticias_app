
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/news_model.dart';
import '../models/category_model.dart';

class NewsService {
  static const String baseUrl =
      'https://news.freepi.io/wp-json/wp/v2/posts';

  static const String categoriesUrl =
      'https://news.freepi.io/wp-json/wp/v2/categories';

  int totalPages = 1;

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

  Future<List<NewsModel>> _fetchNews({
    int page = 1,
    int perPage = 10,
    String? search,
    int? categoryId,
  }) async {
    final Map<String, String> parameters = {
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (search != null && search.trim().isNotEmpty) {
      parameters['search'] = search.trim();
    }

    if (categoryId != null) {
      parameters['categories'] = categoryId.toString();
    }

    final uri = Uri.parse(baseUrl).replace(
      queryParameters: parameters,
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      totalPages = int.tryParse(
            response.headers['x-wp-totalpages'] ?? '',
          ) ??
          1;

      final news = _parseNews(response.body);

      print('Página consultada: $page');
      print('Noticias recibidas: ${news.length}');
      print('Total de páginas: $totalPages');

      return news;
    } else {
      throw Exception(
        'Error al obtener noticias: ${response.statusCode}',
      );
    }
  }

  Future<List<NewsModel>> getNews({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      return await _fetchNews(
        page: page,
        perPage: perPage,
      );
    } catch (e) {
      print('Error de conexión: $e');
      rethrow;
    }
  }

  Future<List<NewsModel>> searchNews(
    String query, {
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final news = await _fetchNews(
        page: page,
        perPage: perPage,
        search: query,
      );

      print('Búsqueda realizada: $query');

      return news;
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
    int categoryId, {
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      return await _fetchNews(
        page: page,
        perPage: perPage,
        categoryId: categoryId,
      );
    } catch (e) {
      print('Error al filtrar por categoría: $e');
      rethrow;
    }
  }
}
