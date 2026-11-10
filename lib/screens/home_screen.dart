
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

      final categories =
          await _newsService.getCategories();

      if (!mounted) return;

      _newsProvider.reportOnline();

      try {
        await _newsProvider.saveCategories(categories);
      } catch (e) {
        debugPrint(
          'No se pudieron guardar categorías: $e',
        );
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
      debugPrint(
        'No fue posible consultar categorías: $e',
      );

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

    final previousNews =
        List<NewsModel>.from(_news);

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
      final cachedNews =
          await _newsProvider.getCachedNews(
        search: normalizedSearch,
        categoryId: categoryId,
      );

      if (!mounted ||
          requestVersion != _requestVersion) {
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

      if (!mounted ||
          requestVersion != _requestVersion) {
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
        debugPrint(
          'Error al guardar caché de noticias: $e',
        );
      }

      if (!mounted ||
          requestVersion != _requestVersion) {
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

      if (!mounted ||
          requestVersion != _requestVersion) {
        return false;
      }

      _newsProvider.reportOffline();

      final cachedNews =
          await _newsProvider.getCachedNews(
        search: normalizedSearch,
        categoryId: categoryId,
      );

      if (!mounted ||
          requestVersion != _requestVersion) {
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

      if (!mounted ||
          requestVersion != _requestVersion) {
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
        debugPrint(
          'Error al guardar más noticias en caché: $e',
        );
      }

      if (!mounted ||
          requestVersion != _requestVersion) {
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
      debugPrint(
        'Error al cargar más noticias: $e',
      );

      if (!mounted ||
          requestVersion != _requestVersion) {
        return;
      }

      _newsProvider.reportOffline();

      final cachedNews =
          await _newsProvider.getCachedNews(
        search: _hasSearched ? _currentQuery : null,
        categoryId: _selectedCategoryId,
      );

      if (!mounted ||
          requestVersion != _requestVersion) {
        return;
      }

      setState(() {
        if (cachedNews != null &&
            cachedNews.isNotEmpty) {
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

  // --------------------------------------------------
  // NAVEGACIÓN Y SESIÓN
  // --------------------------------------------------

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

  
  Widget _buildPageIntro() {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 19, 20, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PORTADA',
            style: TextStyle(
              color: colors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Explora la actualidad',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Las noticias importantes, en un solo lugar.',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  

  Widget _buildSearchField() {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 12),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        style: TextStyle(
          color: colors.onSurface,
          fontSize: 14,
        ),
        onChanged: (_) {
          setState(() {});
        },
        onSubmitted: (_) => _searchNews(),
        decoration: InputDecoration(
          hintText: 'Buscar noticias o temas...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchController.text.isEmpty
              ? IconButton(
                  onPressed: _searchNews,
                  tooltip: 'Buscar',
                  style: IconButton.styleFrom(
                    backgroundColor: colors.primaryContainer,
                    foregroundColor: colors.primary,
                  ),
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                  ),
                )
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                    _loadNews();
                  },
                  tooltip: 'Limpiar búsqueda',
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      ),
    );
  }



  Widget _buildCategorySelector() {
    final colors = Theme.of(context).colorScheme;

    final heading = Padding(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 11),
      child: Row(
        children: [
          Text(
            'Explora por categoría',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          if (_categories.isNotEmpty)
            Text(
              '${_categories.length} temas',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );

    if (_isLoadingCategories) {
      return Column(
        children: [
          heading,
          Padding(
            padding: const EdgeInsets.all(13),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.primary,
              ),
            ),
          ),
        ],
      );
    }

    if (_categoryError != null &&
        _categories.isEmpty) {
      return Column(
        children: [
          heading,
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
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
                  icon: const Icon(
                    Icons.refresh_rounded,
                  ),
                  label: const Text(
                    'Reintentar categorías',
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading,
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                ),
                child: ChoiceChip(
                  label: const Text('Todas'),
                  selected: _selectedCategoryId == null &&
                      !_hasSearched,
                  showCheckmark: false,
                  selectedColor: colors.primary,
                  backgroundColor: colors.surface,
                  side: BorderSide(
                    color: colors.outline.withValues(
                      alpha: 0.45,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  labelStyle: TextStyle(
                    color: _selectedCategoryId == null &&
                            !_hasSearched
                        ? colors.onPrimary
                        : colors.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: (_) =>
                      _filterByCategory(null),
                ),
              ),
              ..._categories.map((category) {
                final isSelected =
                    _selectedCategoryId == category.id;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  child: ChoiceChip(
                    label: Text(category.name),
                    selected: isSelected,
                    showCheckmark: false,
                    selectedColor: colors.primary,
                    backgroundColor: colors.surface,
                    side: BorderSide(
                      color: isSelected
                          ? colors.primary
                          : colors.outline.withValues(
                              alpha: 0.45,
                            ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? colors.onPrimary
                          : colors.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) =>
                        _filterByCategory(category),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  
  Widget _buildOfflineBanner(NewsProvider provider) {
    if (provider.isOnline &&
        !_isUsingCache &&
        !_offlineCacheEmpty) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;

    final isSyncing =
        provider.isOnline && _isUsingCache;

    final message = _offlineCacheEmpty
        ? 'Sin conexión. No hay noticias guardadas para esta consulta.'
        : isSyncing
            ? 'Conexión recuperada. Actualizando noticias...'
            : 'Modo sin conexión. Mostrando noticias almacenadas.';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: colors.primary.withValues(
            alpha: 0.12,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSyncing
                ? Icons.sync_rounded
                : Icons.cloud_off_rounded,
            color: colors.onPrimaryContainer,
            size: 21,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.onPrimaryContainer,
                fontSize: 11,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isSyncing)
            SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.onPrimaryContainer,
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
          Text(
            'Cargando noticias...',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
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
            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                color: colors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 42,
                color: colors.error,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _errorMessage ?? 'Ocurrió un error.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refreshNews,
              icon: const Icon(Icons.refresh_rounded),
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
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                offline
                    ? Icons.cloud_off_rounded
                    : _hasSearched
                        ? Icons.search_off_rounded
                        : Icons.newspaper_rounded,
                size: 42,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              offline
                  ? 'No hay noticias guardadas para mostrar sin conexión.'
                  : _hasSearched
                      ? 'No existen publicaciones relacionadas con "$_currentQuery".'
                      : 'No hay noticias disponibles para esta selección.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
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
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
                label: const Text(
                  'Ver todas las noticias',
                ),
              ),
            ],
            if (offline) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _refreshNews,
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
                label: const Text(
                  'Intentar nuevamente',
                ),
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
        padding: const EdgeInsets.symmetric(
          vertical: 24,
        ),
        child: Column(
          children: [
            CircularProgressIndicator(
              color: colors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Cargando más noticias...',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (_loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
        ),
        child: Column(
          children: [
            Text(
              _loadMoreError!,
              textAlign: TextAlign.center,
            ),
            TextButton.icon(
              onPressed: _loadMoreNews,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'Intentar nuevamente',
              ),
            ),
          ],
        ),
      );
    }

    if (_hasMore && !_isUsingCache) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 24,
        ),
        child: Center(
          child: Text(
            'Desplázate para cargar más noticias',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 24,
      ),
      child: Center(
        child: Text(
          'Has llegado al final de las noticias guardadas.',
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }


  Widget _buildNewsList() {
    final colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _refreshNews,
      color: colors.primary,
      backgroundColor: colors.surface,
      displacement: 45,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          18,
          12,
          18,
          18,
        ),
        itemCount: _news.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(
                bottom: 17,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasSearched
                              ? 'Resultados de búsqueda'
                              : 'Últimas noticias',
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _hasSearched
                              ? 'Coincidencias para "$_currentQuery"'
                              : 'Mantente al día con lo más reciente.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_news.length}',
                      style: TextStyle(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final newsIndex = index - 1;

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
        titleSpacing: 18,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.newspaper_rounded,
                color: colors.primary,
                size: 23,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Noticias App'),
          ],
        ),
        actions: [
          Consumer<AppProvider>(
            builder: (context, appProvider, child) {
              return IconButton(
                onPressed: appProvider.toggleTheme,
                icon: Icon(
                  appProvider.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
                tooltip: appProvider.isDarkMode
                    ? 'Activar modo claro'
                    : 'Activar modo oscuro',
              );
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'Más opciones',
            icon: const Icon(
              Icons.more_vert_rounded,
            ),
            onSelected: (value) {
              if (value == 'profile') {
                _openProfile();
              } else if (value == 'bookmarks') {
                _openBookmarks();
              } else if (value == 'refresh') {
                _refreshNews();
              } else if (value == 'logout') {
                _confirmSignOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline_rounded),
                    SizedBox(width: 12),
                    Text('Mi perfil'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'bookmarks',
                child: Row(
                  children: [
                    Icon(Icons.bookmark_border_rounded),
                    SizedBox(width: 12),
                    Text('Mis favoritos'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded),
                    SizedBox(width: 12),
                    Text('Actualizar noticias'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded),
                    SizedBox(width: 12),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          _buildPageIntro(),
          _buildSearchField(),
          _buildCategorySelector(),
          _buildOfflineBanner(connectionProvider),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(
                milliseconds: 250,
              ),
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
    );
  }
}
