
import 'package:flutter/material.dart';

import '../models/news_model.dart';
import '../models/category_model.dart';
import '../services/news_service.dart';
import '../components/news_card.dart';
import 'bookmarks_screen.dart';

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

  final ScrollController _scrollController =
      ScrollController();

  static const int _perPage = 10;

  List<NewsModel> _news = [];
  List<CategoryModel> _categories = [];

  int? _selectedCategoryId;
  int _currentPage = 1;

  bool _isLoading = true;
  bool _isLoadingCategories = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _hasSearched = false;

  String? _errorMessage;
  String? _categoryError;
  String? _loadMoreError;

  String _currentQuery = '';
  int _requestVersion = 0;

  @override
  void initState() {
    super.initState();

    _newsService = widget.newsService ?? NewsService();

    _scrollController.addListener(_onScroll);

    _loadCategories();
    _loadNews();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;

    if (position.pixels >=
        position.maxScrollExtent - 300) {
      _loadMoreNews();
    }
  }
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
        _categoryError =
            'No fue posible cargar las categorías.';
      });
    }
  }

  Future<void> _loadFirstPage({
    String? search,
    int? categoryId,
  }) async {
    final requestVersion = ++_requestVersion;

    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _hasMore = true;
      _currentPage = 1;
      _errorMessage = null;
      _loadMoreError = null;
      _news = [];
    });

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    try {
      List<NewsModel> results;

      if (search != null && search.isNotEmpty) {
        results = await _newsService.searchNews(
          search,
          page: 1,
          perPage: _perPage,
        );
      } else if (categoryId != null) {
        results = await _newsService.getNewsByCategory(
          categoryId,
          page: 1,
          perPage: _perPage,
        );
      } else {
        results = await _newsService.getNews(
          page: 1,
          perPage: _perPage,
        );
      }

      if (!mounted || requestVersion != _requestVersion) {
        return;
      }

      setState(() {
        _news = results;
        _currentPage = 1;
        _hasMore = results.isNotEmpty &&
            _currentPage < _newsService.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestVersion != _requestVersion) {
        return;
      }

      setState(() {
        _errorMessage =
            'No fue posible cargar las noticias.';
        _isLoading = false;
        _hasMore = false;
      });
    }
  }

  Future<void> _loadNews() async {
    _selectedCategoryId = null;
    _hasSearched = false;
    _currentQuery = '';
    _searchController.clear();

    await _loadFirstPage();
  }

  Future<void> _searchNews() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      await _loadNews();
      return;
    }

    _selectedCategoryId = null;
    _hasSearched = true;
    _currentQuery = query;

    await _loadFirstPage(search: query);
  }
  Future<void> _filterByCategory(
    CategoryModel? category,
  ) async {
    _searchController.clear();

    _selectedCategoryId = category?.id;
    _hasSearched = false;
    _currentQuery = '';

    await _loadFirstPage(
      categoryId: category?.id,
    );
  }
  Future<void> _loadMoreNews() async {
    if (_isLoading ||
        _isLoadingMore ||
        !_hasMore ||
        _loadMoreError != null) {
      return;
    }

    final nextPage = _currentPage + 1;
    final requestVersion = _requestVersion;

    setState(() {
      _isLoadingMore = true;
      _loadMoreError = null;
    });

    try {
      List<NewsModel> results;

      if (_hasSearched && _currentQuery.isNotEmpty) {
        results = await _newsService.searchNews(
          _currentQuery,
          page: nextPage,
          perPage: _perPage,
        );
      } else if (_selectedCategoryId != null) {
        results = await _newsService.getNewsByCategory(
          _selectedCategoryId!,
          page: nextPage,
          perPage: _perPage,
        );
      } else {
        results = await _newsService.getNews(
          page: nextPage,
          perPage: _perPage,
        );
      }

      if (!mounted || requestVersion != _requestVersion) {
        return;
      }

      setState(() {
        _news.addAll(results);
        _currentPage = nextPage;

        _hasMore = results.isNotEmpty &&
            _currentPage < _newsService.totalPages;

        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted || requestVersion != _requestVersion) {
        return;
      }

      setState(() {
        _isLoadingMore = false;
        _loadMoreError =
            'No fue posible cargar más noticias.';
      });
    }
  }
  Future<void> _refreshNews() async {
    await _loadFirstPage(
      search: _hasSearched ? _currentQuery : null,
      categoryId: _selectedCategoryId,
    );
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

  Widget _buildLoadMoreFooter() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            CircularProgressIndicator(
              color: Colors.deepPurple,
            ),
            SizedBox(height: 12),
            Text('Cargando más noticias...'),
          ],
        ),
      );
    }

    if (_loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(_loadMoreError!),
            TextButton.icon(
              onPressed: _loadMoreNews,
              icon: const Icon(Icons.refresh),
              label: const Text('Intentar nuevamente'),
            ),
          ],
        ),
      );
    }

    if (_hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Desplázate para cargar más noticias',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'Has llegado al final de las noticias.',
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNewsList() {
    final headerCount = _hasSearched ? 1 : 0;

    return RefreshIndicator(
      onRefresh: _refreshNews,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _news.length + headerCount + 1,
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

          final newsIndex = index - headerCount;

          if (newsIndex < _news.length) {
            return NewsCard(
              news: _news[newsIndex],
            );
          }

          return _buildLoadMoreFooter();
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const BookmarksScreen(),
                ),
              );
            },
            icon: const Icon(Icons.bookmark),
            tooltip: 'Mis noticias guardadas',
          ),
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
