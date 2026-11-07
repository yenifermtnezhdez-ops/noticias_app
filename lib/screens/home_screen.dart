
import 'package:flutter/material.dart';

import '../models/news_model.dart';
import '../models/category_model.dart';
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
  List<CategoryModel> _categories = [];

  int? _selectedCategoryId;

  bool _isLoading = true;
  bool _isLoadingCategories = true;
  bool _hasSearched = false;

  String? _errorMessage;
  String? _categoryError;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();

    _newsService = widget.newsService ?? NewsService();

    _loadCategories();
    _loadNews();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Obtiene las categorías desde WordPress.
  Future<void> _loadCategories() async {
    try {
      final categories = await _newsService.getCategories();

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
        _categoryError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingCategories = false;
        _categoryError = 'No fue posible cargar las categorías.';
      });
    }
  }

  // Carga todas las noticias.
  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = false;
      _currentQuery = '';
      _selectedCategoryId = null;
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

  // Busca noticias mediante un término.
  Future<void> _searchNews() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      await _loadNews();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
      _currentQuery = query;
      _selectedCategoryId = null;
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

  // Filtra las noticias por categoría.
  Future<void> _filterByCategory(
    CategoryModel? category,
  ) async {
    _searchController.clear();

    setState(() {
      _selectedCategoryId = category?.id;
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = false;
      _currentQuery = '';
    });

    try {
      final results = category == null
          ? await _newsService.getNews()
          : await _newsService.getNewsByCategory(category.id);

      if (!mounted) return;

      setState(() {
        _news = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'No fue posible filtrar las noticias.';
        _isLoading = false;
      });
    }
  }

  // Actualiza la vista sin perder el filtro seleccionado.
  Future<void> _refreshNews() async {
    if (_hasSearched && _currentQuery.isNotEmpty) {
      _searchController.text = _currentQuery;
      await _searchNews();
    } else if (_selectedCategoryId != null) {
      final category = _categories.firstWhere(
        (item) => item.id == _selectedCategoryId,
      );

      await _filterByCategory(category);
    } else {
      await _loadNews();
    }
  }

  // Campo de búsqueda.
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

  // Selector horizontal de categorías.
  Widget _buildCategorySelector() {
    if (_isLoadingCategories) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(
          child: SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.deepPurple,
            ),
          ),
        ),
      );
    }

    if (_categoryError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        child: Text(
          _categoryError!,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 12,
          ),
        ),
      );
    }

    return SizedBox(
      height: 55,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: const Text('Todas'),
              selected: _selectedCategoryId == null &&
                  !_hasSearched,
              selectedColor: Colors.deepPurple,
              labelStyle: TextStyle(
                color: _selectedCategoryId == null &&
                        !_hasSearched
                    ? Colors.white
                    : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) => _filterByCategory(null),
            ),
          ),
          ..._categories.map((category) {
            final isSelected =
                _selectedCategoryId == category.id;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(category.name),
                selected: isSelected,
                selectedColor: Colors.deepPurple,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) =>
                    _filterByCategory(category),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Indicador de carga.
  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.deepPurple,
          ),
          SizedBox(height: 16),
          Text('Cargando noticias...'),
        ],
      ),
    );
  }

  // Mensaje de error.
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
              onPressed: _refreshNews,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  // Mensaje cuando no hay resultados.
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
                  : 'No hay noticias disponibles para esta selección.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            if (_hasSearched ||
                _selectedCategoryId != null) ...[
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

  // Listado de noticias.
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

          final newsIndex =
              _hasSearched ? index - 1 : index;

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
            onPressed: _refreshNews,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar noticias',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(),
          _buildCategorySelector(),
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
