
import 'dart:convert';

import 'package:http/http.dart' as http;

class NewsService {
  static const String baseUrl =
      'https://news.freepi.io/wp-json/wp/v2/posts';
  Future<List<dynamic>> getNews() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
      );
      if (response.statusCode == 200) {
        // Convertir la respuesta JSON.
        final data = jsonDecode(response.body);

        print('Conexión exitosa con WordPress');
        print('Noticias recibidas: ${data.length}');

        return data;
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
}
