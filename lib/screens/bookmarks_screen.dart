
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/news_model.dart';
import '../providers/bookmark_provider.dart';
import '../services/news_service.dart';
import '../components/news_card.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final NewsService _newsService = NewsService();

  BookmarkProvider? _bookmarkProvider;

  List<int>? _requestedIds;
  Future<List<NewsModel>>? _newsFuture;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _bookmarkProvider = context.read<BookmarkProvider>();

      _bookmarkProvider!.addListener(_onBookmarksChanged);

      _syncBookmarks();
    });
  }

  @override
  void dispose() {
    _bookmarkProvider?.removeListener(_onBookmarksChanged);
    super.dispose();
  }


  void _onBookmarksChanged() {
    _syncBookmarks();
  }

  void _syncBookmarks() {
    if (!mounted || _bookmarkProvider == null) return;

    if (!_bookmarkProvider!.isLoaded) return;

    final ids = _bookmarkProvider!.bookmarkedIds.toList();

    if (_sameIds(ids, _requestedIds)) return;

    setState(() {
      _requestedIds = ids;

      if (ids.isEmpty) {
        _newsFuture = Future.value([]);
      } else {
        _newsFuture = _newsService.getNewsByIds(ids);
      }
    });
  }

  bool _sameIds(List<int> current, List<int>? previous) {
    if (previous == null || current.length != previous.length) {
      return false;
    }

    for (int i = 0; i < current.length; i++) {
      if (current[i] != previous[i]) {
        return false;
      }
    }

    return true;
  }

  Future<void> _refreshBookmarks() async {
    if (!mounted || _bookmarkProvider == null) return;

    final ids = _bookmarkProvider!.bookmarkedIds.toList();

    if (ids.isEmpty) {
      setState(() {
        _requestedIds = [];
        _newsFuture = Future.value([]);
      });
      return;
    }

    final future = _newsService.getNewsByIds(ids);

    setState(() {
      _requestedIds = ids;
      _newsFuture = future;
    });

    try {
      await future;
    } catch (e) {
      debugPrint('Error al actualizar favoritos: $e');
    }
  }


  Widget _buildHeader(int count) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.bookmarks_rounded,
              color: colors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu colección personal',
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Guarda y consulta tus noticias favoritas.',
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                  ),
                ),
                Text(
                  'Guardadas',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 9,
                  ),
                ),
              ],
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
            'Cargando noticias guardadas...',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 105,
              height: 105,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_border_rounded,
                size: 49,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 23),
            Text(
              'Tu colección está vacía',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Cuando encuentres una noticia interesante, '
              'guárdala con el icono de marcador para '
              'consultarla aquí más tarde.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildError() {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
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
                Icons.cloud_off_rounded,
                size: 40,
                color: colors.error,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No pudimos cargar tus favoritos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              'Comprueba tu conexión a Internet e inténtalo nuevamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 19),
            ElevatedButton.icon(
              onPressed: _refreshBookmarks,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Intentar nuevamente'),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildUnavailable() {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 55,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 15),
            Text(
              'Las noticias guardadas ya no están disponibles.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 13),
            TextButton.icon(
              onPressed: _refreshBookmarks,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }

  

  Widget _buildNewsList(List<NewsModel> news) {
    final colors = Theme.of(context).colorScheme;

    if (news.isEmpty) {
      return _buildUnavailable();
    }

    return RefreshIndicator(
      onRefresh: _refreshBookmarks,
      color: colors.primary,
      backgroundColor: colors.surface,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          18,
          17,
          18,
          25,
        ),
        itemCount: news.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 17),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Noticias guardadas',
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tu selección personal de actualidad.',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.favorite_rounded,
                    color: colors.primary,
                  ),
                ],
              ),
            );
          }

          final item = news[index - 1];

          return NewsCard(
            key: ValueKey(item.id),
            news: item,
          );
        },
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final bookmarkProvider =
        context.watch<BookmarkProvider>();

    Widget content;

    if (!bookmarkProvider.isLoaded ||
        _newsFuture == null) {
      content = _buildLoading();
    } else if (bookmarkProvider.bookmarkedIds.isEmpty) {
      content = _buildEmpty();
    } else {
      content = FutureBuilder<List<NewsModel>>(
        future: _newsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return _buildLoading();
          }

          if (snapshot.hasError) {
            return _buildError();
          }

          return _buildNewsList(snapshot.data ?? []);
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis favoritos'),
        actions: [
          IconButton(
            onPressed: !bookmarkProvider.isLoaded
                ? null
                : _refreshBookmarks,
            tooltip: 'Actualizar favoritos',
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 17, 18, 0),
        child: Column(
          children: [
            _buildHeader(
              bookmarkProvider.bookmarkedIds.length,
            ),
            const SizedBox(height: 15),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey(
                    '${bookmarkProvider.bookmarkedIds.length}-'
                    '${bookmarkProvider.isLoaded}',
                  ),
                  child: content,
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: colors.surface,
    );
  }
}
