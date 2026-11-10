
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../models/news_model.dart';
import '../models/category_model.dart';
import '../services/cache_service.dart';

class NewsProvider extends ChangeNotifier
    with WidgetsBindingObserver {
  final Connectivity _connectivity;
  final CacheService _cacheService;

  StreamSubscription<List<ConnectivityResult>>?
      _connectivitySubscription;

  bool _isOnline = true;
  bool _isInitialized = false;
  bool _isCheckingConnection = false;

  int _connectionRevision = 0;

  String? _errorMessage;

  NewsProvider({
    Connectivity? connectivity,
    CacheService? cacheService,
  })  : _connectivity = connectivity ?? Connectivity(),
        _cacheService = cacheService ?? CacheService();

  bool get isOnline => _isOnline;

  bool get isOffline => !_isOnline;

  bool get isInitialized => _isInitialized;

  bool get isCheckingConnection => _isCheckingConnection;

  int get connectionRevision => _connectionRevision;

  String? get errorMessage => _errorMessage;


  Future<void> initialize() async {
    if (_isInitialized) return;

    _isInitialized = true;

    WidgetsBinding.instance.addObserver(this);

  
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(
      _updateConnection,
      onError: (error) {
        debugPrint(
          'Error al detectar conexión: $error',
        );

        reportOffline();
      },
    );

  
    await checkConnectivity();
  }


  Future<void> checkConnectivity() async {
    if (_isCheckingConnection) return;

    _isCheckingConnection = true;

    try {
      final results = await _connectivity.checkConnectivity();

      _updateConnection(results);
    } catch (e) {
      debugPrint(
        'Error al comprobar la conexión: $e',
      );

      reportOffline();
    } finally {
      _isCheckingConnection = false;
    }
  }

 
  void _updateConnection(
    List<ConnectivityResult> results,
  ) {
    final hasConnection = results.any(
      (result) => result != ConnectivityResult.none,
    );

    if (_isOnline != hasConnection) {
      _isOnline = hasConnection;
      _connectionRevision++;

      debugPrint(
        _isOnline
            ? 'CONEXIÓN DISPONIBLE'
            : 'DISPOSITIVO SIN CONEXIÓN',
      );

      notifyListeners();
    }
  }


  void reportOnline() {
    _errorMessage = null;

    if (!_isOnline) {
      _isOnline = true;
      _connectionRevision++;

      debugPrint('INTERNET RESTABLECIDO');

      notifyListeners();
    }
  }

  void reportOffline() {
    if (_isOnline) {
      _isOnline = false;
      _connectionRevision++;

      debugPrint('MODO OFFLINE ACTIVADO');

      notifyListeners();
    }
  }

 
  String buildCacheKey({
    String? search,
    int? categoryId,
  }) {
    if (search != null && search.trim().isNotEmpty) {
      final normalizedSearch =
          search.trim().toLowerCase();

      return 'search_${Uri.encodeComponent(normalizedSearch)}';
    }

    if (categoryId != null) {
      return 'category_$categoryId';
    }

    return 'all_news';
  }


  Future<List<NewsModel>?> getCachedNews({
    String? search,
    int? categoryId,
  }) async {
    final key = buildCacheKey(
      search: search,
      categoryId: categoryId,
    );

    return _cacheService.getNews(key);
  }

 
  Future<void> saveNews({
    required List<NewsModel> news,
    String? search,
    int? categoryId,
    bool append = false,
  }) async {
    final key = buildCacheKey(
      search: search,
      categoryId: categoryId,
    );

    await _cacheService.saveNews(
      cacheKey: key,
      news: news,
      append: append,
    );
  }


  Future<List<CategoryModel>?> getCachedCategories() {
    return _cacheService.getCategories();
  }

  Future<void> saveCategories(
    List<CategoryModel> categories,
  ) {
    return _cacheService.saveCategories(categories);
  }

 
  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      checkConnectivity();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _connectivitySubscription?.cancel();

    super.dispose();
  }
}
