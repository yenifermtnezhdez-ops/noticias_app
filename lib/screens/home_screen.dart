
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/news_model.dart';
import '../models/category_model.dart';

import '../services/news_service.dart';

import '../components/news_card.dart';

import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/news_provider.dart';

import 'bookmarks_screen.dart';
import 'profile_screen.dart';

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
  late final NewsProvider _newsProvider;

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
  bool _isRefreshing = false;

  bool _hasMore = true;
  bool _hasSearched = false;

  bool _isUsingCache = false;
  bool _offlineCacheEmpty = false;
  bool _isSyncingAfterReconnect = false;

  bool _lastKnownOnline = true;

  String? _errorMessage;
  String? _categoryError;
  String? _loadMoreError;

  String _currentQuery = '';

  int _requestVersion = 0;

  @override
  void initState() {
    super.initState();

    _newsService = widget.newsService ?? NewsService();

    _newsProvider = context.read<NewsProvider>();

    _lastKnownOnline = _newsProvider.isOnline;

  
    _newsProvider.addListener(_onConnectionChanged);

    _scrollController.addListener(_onScroll);

    _loadCategories();
    _loadNews();
  }

  @override
  void dispose() {
    _newsProvider.removeListener(_onConnectionChanged);

    _searchController.dispose();
    _scrollController.dispose();

    super.dispose();
  }


  void _onConnectionChanged() {
    if (!mounted) return;

    final isOnline = _newsProvider.isOnline;

    final connectionRestored =
        !_lastKnownOnline && isOnline;

    _lastKnownOnline = isOnline;

    setState(() {});

    if (connectionRestored) {
      debugPrint(
        'INTERNET RESTABLECIDO: iniciando sincronización.',
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _syncAfterReconnect();
        }
      });
    }
  }


  Future<void> _syncAfterReconnect() async {
    if (!mounted || _isSyncingAfterReconnect) return;

    if (_isLoading || _isRefreshing || _isLoadingMore) {
      return;
    }

    _isSyncingAfterReconnect = true;

    try {
      await _loadCategories();

      if (!mounted) return;

      final success = await _loadFirstPage(
        search: _hasSearched ? _currentQuery : null,
        categoryId: _selectedCategoryId,
        preserveExistingNews: true,
      );

      if (!mounted) return;

      if (success &&
          _newsProvider.isOnline &&
          !_isUsingCache) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Conexión recuperada. Noticias actualizadas.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      _isSyncingAfterReconnect = false;
    }
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
    if (!mounted) return;

    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });

    try {
      if (!_newsProvider.isOnline) {
        throw Exception('Sin conexión.');
      }

      final categories = await _newsService.getCategories();

      if (!mounted) return;

      _newsProvider.reportOnline();

     
      try {
        await _newsProvider.saveCategories(categories);
      } catch (e) {
        debugPrint('No se pudieron guardar categorías: $e');
      }

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
        _categoryError = null;
      });

      debugPrint(
        'Categorías cargadas desde WordPress: ${categories.length}',
      );
    } catch (e) {
      debugPrint('No fue posible consultar categorías: $e');

      _newsProvider.reportOffline();

      final cachedCategories =
          await _newsProvider.getCachedCategories();

      if (!mounted) return;

      if (cachedCategories != null &&
          cachedCategories.isNotEmpty) {
        setState(() {
          _categories = cachedCategories;
          _isLoadingCategories = false;
          _categoryError = null;
        });

        debugPrint(
          'Categorías recuperadas desde caché.',
        );
      } else {
        setState(() {
          _categories = [];
          _isLoadingCategories = false;
          _categoryError =
              'No hay categorías almacenadas. '
              'Conéctate a Internet para cargarlas.';
        });
      }
    }
  }


  Future<bool> _loadFirstPage({
    String? search,
    int? categoryId,
    bool preserveExistingNews = false,
  }) async {
    final requestVersion = ++_requestVersion;

    final normalizedSearch =
        search != null && search.trim().isNotEmpty
            ? search.trim()
            : null;

   final previousNews = List<NewsModel>.from(_news);
final previousPage = _currentPage;

    final hadPreviousNews = previousNews.isNotEmpty;

    setState(() {
      _isLoading = !preserveExistingNews ||
          !hadPreviousNews;

      _isRefreshing = preserveExistingNews &&
          hadPreviousNews;

      _isLoadingMore = false;
      _loadMoreError = null;
      _errorMessage = null;

      _offlineCacheEmpty = false;

      if (!preserveExistingNews) {
        _hasMore = true;
        _currentPage = 1;
        _news = [];
        _isUsingCache = false;
      }
    });

    if (!preserveExistingNews &&
        _scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

   
    if (!_newsProvider.isOnline) {
      final cachedNews = await _newsProvider.getCachedNews(
        search: normalizedSearch,
        categoryId: categoryId,
      );

      if (!mounted || requestVersion != _requestVersion) {
        return false;
      }

      final hasCache =
          cachedNews != null && cachedNews.isNotEmpty;

      final availableNews = hasCache
          ? cachedNews
          : preserveExistingNews && hadPreviousNews
              ? previousNews
              : <NewsModel>[];

      setState(() {
        _news = availableNews;
        _currentPage = 1;
        _hasMore = false;

        _isUsingCache = availableNews.isNotEmpty;

        _offlineCacheEmpty = availableNews.isEmpty;

        _isLoading = false;
        _isRefreshing = false;
        _isLoadingMore = false;

        _errorMessage = null;
      });

      debugPrint(
        availableNews.isNotEmpty
            ? 'NOTICIAS RECUPERADAS DESDE CACHÉ OFFLINE.'
            : 'OFFLINE: no hay noticias almacenadas para esta consulta.',
      );

      return availableNews.isNotEmpty;
    }

    try {
      List<NewsModel> results;

      if (normalizedSearch != null) {
        results = await _newsService.searchNews(
          normalizedSearch,
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
        return false;
      }

      _newsProvider.reportOnline();

     
      try {
        await _newsProvider.saveNews(
          news: results,
          search: normalizedSearch,
          categoryId: categoryId,
          append: false,
        );
      } catch (e) {
        debugPrint('Error al guardar caché de noticias: $e');
      }

      if (!mounted || requestVersion != _requestVersion) {
        return false;
      }

      setState(() {
        _news = results;
        _currentPage = 1;

        _hasMore = results.isNotEmpty &&
            _currentPage < _newsService.totalPages;

        _isUsingCache = false;
        _offlineCacheEmpty = false;

        _isLoading = false;
        _isRefreshing = false;
        _isLoadingMore = false;

        _errorMessage = null;
      });

      return true;
    } catch (e) {
      debugPrint('Error al cargar noticias: $e');

      if (!mounted || requestVersion != _requestVersion) {
        return false;
      }

      
      _newsProvider.reportOffline();

      final cachedNews = await _newsProvider.getCachedNews(
        search: normalizedSearch,
        categoryId: categoryId,
      );

      if (!mounted || requestVersion != _requestVersion) {
        return false;
      }

      final hasCache =
          cachedNews != null && cachedNews.isNotEmpty;

      final availableNews = hasCache
          ? cachedNews
          : preserveExistingNews && hadPreviousNews
              ? previousNews
              : <NewsModel>[];

      setState(() {
        _news = availableNews;

        _currentPage = preserveExistingNews && !hasCache
            ? previousPage
            : 1;

        _hasMore = false;

        _isUsingCache = availableNews.isNotEmpty;

        _offlineCacheEmpty = availableNews.isEmpty;

        _isLoading = false;
        _isRefreshing = false;
        _isLoadingMore = false;

        _errorMessage = null;
      });

      debugPrint(
        availableNews.isNotEmpty
            ? 'Se muestran noticias almacenadas localmente.'
            : 'No hay noticias disponibles en la caché.',
      );

      return availableNews.isNotEmpty;
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
        _isRefreshing ||
        !_hasMore ||
        _loadMoreError != null ||
        _isUsingCache ||
        !_newsProvider.isOnline) {
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

      _newsProvider.reportOnline();

      try {
        await _newsProvider.saveNews(
          news: results,
          search: _hasSearched ? _currentQuery : null,
          categoryId: _selectedCategoryId,
          append: true,
        );
      } catch (e) {
        debugPrint('Error al guardar más noticias en caché: $e');
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
      debugPrint('Error al cargar más noticias: $e');

      if (!mounted || requestVersion != _requestVersion) {
        return;
      }

      _newsProvider.reportOffline();

      final cachedNews = await _newsProvider.getCachedNews(
        search: _hasSearched ? _currentQuery : null,
        categoryId: _selectedCategoryId,
      );

      if (!mounted || requestVersion != _requestVersion) {
        return;
      }

      setState(() {
        if (cachedNews != null && cachedNews.isNotEmpty) {
          _news = cachedNews;
          _isUsingCache = true;
          _hasMore = false;
          _loadMoreError = null;
        } else {
          _loadMoreError =
              'No fue posible cargar más noticias. '
              'Se conserva el contenido disponible.';
        }

        _isLoadingMore = false;
      });
    }
  }

  
  Future<void> _refreshNews() async {
    await _loadCategories();

    if (!mounted) return;

    final success = await _loadFirstPage(
      search: _hasSearched ? _currentQuery : null,
      categoryId: _selectedCategoryId,
      preserveExistingNews: true,
    );

    if (!mounted || success) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No fue posible actualizar las noticias. '
          'Se conserva el contenido disponible.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  
  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text(
            '¿Estás seguro de que deseas cerrar tu sesión?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true || !mounted) return;

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.signOut();

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ??
                'No fue posible cerrar la sesión.',
          ),
        ),
      );
    }
  }

 
  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );
  }


  void _openBookmarks() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BookmarksScreen(),
      ),
    );
  }

 
  Widget _buildSearchField() {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        style: TextStyle(color: colors.onSurface),
        onSubmitted: (_) => _searchNews(),
        decoration: InputDecoration(
          hintText: 'Buscar noticias...',
          prefixIcon: Icon(
            Icons.search,
            color: colors.primary,
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
        ),
      ),
    );
  }

  
  Widget _buildCategorySelector() {
    final colors = Theme.of(context).colorScheme;

    if (_isLoadingCategories) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.primary,
            ),
          ),
        ),
      );
    }

    if (_categoryError != null && _categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        child: Column(
          children: [
            Text(
              _categoryError!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.error,
                fontSize: 12,
              ),
            ),
            TextButton.icon(
              onPressed: _loadCategories,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar categorías'),
            ),
          ],
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
              selectedColor: colors.primary,
              backgroundColor: colors.surface,
              labelStyle: TextStyle(
                color: _selectedCategoryId == null &&
                        !_hasSearched
                    ? colors.onPrimary
                    : colors.onSurface,
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
                selectedColor: colors.primary,
                backgroundColor: colors.surface,
                labelStyle: TextStyle(
                  color: isSelected
                      ? colors.onPrimary
                      : colors.onSurface,
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

  
  Widget _buildOfflineBanner(NewsProvider provider) {
    if (provider.isOnline &&
        !_isUsingCache &&
        !_offlineCacheEmpty) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;

    final message = _offlineCacheEmpty
        ? 'Sin conexión. No hay noticias guardadas para esta consulta.'
        : 'Modo sin conexión. Mostrando noticias almacenadas.';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: colors.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.onErrorContainer,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (provider.isOnline && _isUsingCache)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildLoading() {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colors.primary,
          ),
          const SizedBox(height: 16),
          const Text('Cargando noticias...'),
        ],
      ),
    );
  }

  
  Widget _buildError() {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 65,
              color: colors.error,
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
    final colors = Theme.of(context).colorScheme;

    final offline = _offlineCacheEmpty ||
        _newsProvider.isOffline;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              offline
                  ? Icons.cloud_off_outlined
                  : _hasSearched
                      ? Icons.search_off
                      : Icons.newspaper,
              size: 65,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              offline
                  ? 'No hay noticias guardadas para mostrar sin conexión.'
                  : _hasSearched
                      ? 'No existen publicaciones relacionadas con "$_currentQuery".'
                      : 'No hay noticias disponibles para esta selección.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              offline
                  ? 'Conéctate a Internet para cargar contenido actualizado.'
                  : '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            if (!offline &&
                (_hasSearched ||
                    _selectedCategoryId != null)) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _loadNews,
                icon: const Icon(Icons.refresh),
                label: const Text('Ver todas las noticias'),
              ),
            ],
            if (offline) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _refreshNews,
                icon: const Icon(Icons.refresh),
                label: const Text('Intentar nuevamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  
  Widget _buildLoadMoreFooter() {
    final colors = Theme.of(context).colorScheme;

    if (_isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            CircularProgressIndicator(
              color: colors.primary,
            ),
            const SizedBox(height: 12),
            const Text('Cargando más noticias...'),
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

    if (_hasMore && !_isUsingCache) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Desplázate para cargar más noticias',
          ),
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'Has llegado al final de las noticias guardadas.',
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

 
  Widget _buildNewsList() {
    final headerCount = _hasSearched ? 1 : 0;
    final colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _refreshNews,
      color: colors.primary,
      backgroundColor: colors.surface,
      displacement: 45,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _news.length + headerCount + 1,
        itemBuilder: (context, index) {
          if (_hasSearched && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Resultados para: "$_currentQuery"',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
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
    final colors = Theme.of(context).colorScheme;

    
    final connectionProvider =
        context.watch<NewsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Noticias App'),
        actions: [
          Consumer<AppProvider>(
            builder: (context, appProvider, child) {
              return IconButton(
                onPressed: appProvider.toggleTheme,
                icon: Icon(
                  appProvider.isDarkMode
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                tooltip: appProvider.isDarkMode
                    ? 'Activar modo claro'
                    : 'Activar modo oscuro',
              );
            },
          ),
          IconButton(
            onPressed: _openProfile,
            icon: const Icon(Icons.person_outline),
            tooltip: 'Mi perfil',
          ),
          IconButton(
            onPressed: _openBookmarks,
            icon: const Icon(Icons.bookmark),
            tooltip: 'Mis noticias guardadas',
          ),
          IconButton(
            onPressed: _confirmSignOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
          IconButton(
            onPressed: _isRefreshing ? null : _refreshNews,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar noticias',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(),
          _buildCategorySelector(),

        
          _buildOfflineBanner(connectionProvider),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _isLoading
                  ? KeyedSubtree(
                      key: const ValueKey('loading'),
                      child: _buildLoading(),
                    )
                  : _errorMessage != null
                      ? KeyedSubtree(
                          key: const ValueKey('error'),
                          child: _buildError(),
                        )
                      : _news.isEmpty
                          ? KeyedSubtree(
                              key: const ValueKey('empty'),
                              child: _buildEmpty(),
                            )
                          : KeyedSubtree(
                              key: ValueKey(
                                'news-$_requestVersion',
                              ),
                              child: _buildNewsList(),
                            ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _searchNews,
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        tooltip: 'Buscar noticias',
        child: const Icon(Icons.search),
      ),
    );
  }
}
