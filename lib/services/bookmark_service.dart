
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkService {
  static const String _bookmarksKey = 'saved_news_ids';
  Future<List<int>> getBookmarkedIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final savedIds = prefs.getStringList(_bookmarksKey) ?? [];

    final ids = savedIds
        .map((id) => int.tryParse(id))
        .whereType<int>()
        .toList();

    debugPrint('BOOKMARKS: IDs recuperados: $ids');

    return ids;
  }
  Future<bool> isBookmarked(int newsId) async {
    final ids = await getBookmarkedIds();
    return ids.contains(newsId);
  }
  Future<void> addBookmark(int newsId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final savedIds = prefs.getStringList(_bookmarksKey) ?? [];
    final id = newsId.toString();

    if (!savedIds.contains(id)) {
      savedIds.add(id);

      final success = await prefs.setStringList(
        _bookmarksKey,
        savedIds,
      );

      if (!success) {
        throw Exception('No fue posible guardar el favorito.');
      }
    }
    await prefs.reload();

    debugPrint(
      'BOOKMARKS: IDs después de guardar: '
      '${prefs.getStringList(_bookmarksKey)}',
    );
  }
  Future<void> removeBookmark(int newsId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final savedIds = prefs.getStringList(_bookmarksKey) ?? [];

    savedIds.remove(newsId.toString());

    final success = await prefs.setStringList(
      _bookmarksKey,
      savedIds,
    );

    if (!success) {
      throw Exception('No fue posible eliminar el favorito.');
    }

    await prefs.reload();

    debugPrint(
      'BOOKMARKS: IDs después de eliminar: '
      '${prefs.getStringList(_bookmarksKey)}',
    );
  }
}
