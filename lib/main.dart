
import 'package:flutter/material.dart';
import 'services/news_service.dart';

void main() {
  runApp(const NoticiasApp());
}

class NoticiasApp extends StatelessWidget {
  const NoticiasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Noticias App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final NewsService _newsService = NewsService();

  bool _isLoading = false;
  String _message = 'Presiona el botón para consultar las noticias.';

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _message = 'Conectando con WordPress...';
    });

    try {
      final news = await _newsService.getNews();

      if (!mounted) return;

      setState(() {
        _message = 'Conexión exitosa.\n'
            'Noticias recibidas: ${news.length}';
      });

      // Mostrar temporalmente algunos títulos en la consola.
      for (final item in news.take(3)) {
        print('Título: ${item['title']['rendered']}');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message = 'No fue posible obtener las noticias.\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Noticias App'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.newspaper,
                size: 80,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 24),
              const Text(
                'Conexión con WordPress',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _loadNews,
                icon: const Icon(Icons.cloud_download),
                label: const Text('Consultar noticias'),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
