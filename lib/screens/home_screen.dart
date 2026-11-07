
import 'package:flutter/material.dart';

import '../models/news_model.dart';
import '../services/news_service.dart';
import '../components/news_card.dart';

class HomeScreen extends StatefulWidget {
  final NewsService? newsService;

  const HomeScreen({
    super.key,
    this.newsService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final NewsService _newsService;

  final TextEditingController _searchController =
      TextEditingController();

  List<NewsModel> _news = [];
  bool _isLoading = true;
  bool _hasSearched = false;
  String? _errorMessage;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _newsService = widget.newsService ?? NewsService();
    _loadNews();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Carga todas las noticias.
  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = false;
      _currentQuery = '';
      _searchController.clear();
    });

    try {
      final news = await _newsService.getNews();

      if (!mounted) return;

      setState(() {
        _news = news;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'No fue posible cargar las noticias.';
        _isLoading = false;
      });
    }
  }

  // Busca noticias mediante el servicio.
  Future<void> _searchNews() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      _loadNews();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
      _currentQuery = query;
    });

    try {
      final results = await _newsService.searchNews(query);

      if (!mounted) return;

      setState(() {
        _news = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'No fue posible realizar la búsqueda.';
        _isLoading = false;
      });
    }
  }

  // Actualiza la vista actual.
  Future<void> _refreshNews() async {
    if (_hasSearched && _currentQuery.isNotEmpty) {
      _searchController.text = _currentQuery;
      await _searchNews();
    } else {
      await _loadNews();
    }
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _searchNews(),
        decoration: InputDecoration(
          hintText: 'Buscar noticias...',
          prefixIcon: const Icon(
            Icons.search,
            color: Colors.deepPurple,
          ),
          suffixIcon: IconButton(
            onPressed: () {
              if (_searchController.text.isNotEmpty) {
                _loadNews();
              }
            },
            icon: const Icon(Icons.clear),
            tooltip: 'Limpiar búsqueda',
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.deepPurple.withValues(alpha: 0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.deepPurple,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.deepPurple,
          ),
          SizedBox(height: 16),
          Text('Buscando noticias...'),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 65,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Ocurrió un error.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _hasSearched
                  ? _searchNews
                  : _loadNews,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _hasSearched
                  ? Icons.search_off
                  : Icons.newspaper,
              size: 65,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _hasSearched
                  ? 'No existen publicaciones relacionadas con "$_currentQuery".'
                  : 'No hay noticias disponibles.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            if (_hasSearched) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _loadNews,
                icon: const Icon(Icons.refresh),
                label: const Text('Ver todas las noticias'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNewsList() {
    return RefreshIndicator(
      onRefresh: _refreshNews,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _news.length + (_hasSearched ? 1 : 0),
        itemBuilder: (context, index) {
          if (_hasSearched && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Resultados para: "$_currentQuery"',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            );
          }

          final newsIndex = _hasSearched ? index - 1 : index;
          final item = _news[newsIndex];

          return NewsCard(news: item);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Noticias App'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadNews,
            icon: const Icon(Icons.refresh),
            tooltip: 'Ver todas las noticias',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: _isLoading
                ? _buildLoading()
                : _errorMessage != null
                    ? _buildError()
                    : _news.isEmpty
                        ? _buildEmpty()
                        : _buildNewsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _searchNews,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        tooltip: 'Buscar noticias',
        child: const Icon(Icons.search),
      ),
    );
  }
}
