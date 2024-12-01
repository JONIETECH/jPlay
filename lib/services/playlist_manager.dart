import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PlaylistManager {
  static final PlaylistManager instance = PlaylistManager._internal();
  PlaylistManager._internal();

  static const String _playlistsKey = 'playlists';
  static const String _favoritesKey = 'favorites';
  static const String _recentlyPlayedKey = 'recently_played';
  static const String _searchHistoryKey = 'search_history';

  Future<void> createPlaylist(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final playlists = await getPlaylists();
    playlists[name] = [];
    await prefs.setString(_playlistsKey, json.encode(playlists));
  }

  Future<Map<String, List<Map<String, dynamic>>>> getPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_playlistsKey);
    if (data == null) return {};
    return Map<String, List<Map<String, dynamic>>>.from(
      json.decode(data).map((key, value) => MapEntry(
        key,
        (value as List).cast<Map<String, dynamic>>(),
      )),
    );
  }

  Future<void> addToPlaylist(String playlistName, Map<String, dynamic> song) async {
    final prefs = await SharedPreferences.getInstance();
    final playlists = await getPlaylists();
    if (!playlists.containsKey(playlistName)) return;
    
    if (!playlists[playlistName]!.any((s) => s['id'] == song['id'])) {
      playlists[playlistName]!.add(song);
      await prefs.setString(_playlistsKey, json.encode(playlists));
    }
  }

  Future<void> addToFavorites(Map<String, dynamic> song) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    if (!favorites.any((s) => s['id'] == song['id'])) {
      favorites.add(song);
      await prefs.setString(_favoritesKey, json.encode(favorites));
    }
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_favoritesKey);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(
      json.decode(data).map((x) => Map<String, dynamic>.from(x)),
    );
  }

  Future<void> addToRecentlyPlayed(Map<String, dynamic> song) async {
    final prefs = await SharedPreferences.getInstance();
    final recentlyPlayed = await getRecentlyPlayed();
    
    // Remove if already exists
    recentlyPlayed.removeWhere((s) => s['id'] == song['id']);
    
    // Add to beginning
    recentlyPlayed.insert(0, song);
    
    // Keep only last 50 songs
    if (recentlyPlayed.length > 50) {
      recentlyPlayed.removeLast();
    }
    
    await prefs.setString(_recentlyPlayedKey, json.encode(recentlyPlayed));
  }

  Future<List<Map<String, dynamic>>> getRecentlyPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_recentlyPlayedKey);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(
      json.decode(data).map((x) => Map<String, dynamic>.from(x)),
    );
  }

  Future<void> deletePlaylist(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final playlists = await getPlaylists();
    playlists.remove(name);
    await prefs.setString(_playlistsKey, json.encode(playlists));
  }

  Future<void> removeFromPlaylist(String playlistName, String songId) async {
    final prefs = await SharedPreferences.getInstance();
    final playlists = await getPlaylists();
    if (!playlists.containsKey(playlistName)) return;
    
    playlists[playlistName]!.removeWhere((song) => song['id'] == songId);
    await prefs.setString(_playlistsKey, json.encode(playlists));
  }

  Future<void> reorderPlaylist(String playlistName, int oldIndex, int newIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final playlists = await getPlaylists();
    if (!playlists.containsKey(playlistName)) return;

    final songs = playlists[playlistName]!;
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = songs.removeAt(oldIndex);
    songs.insert(newIndex, item);
    
    await prefs.setString(_playlistsKey, json.encode(playlists));
  }

  Future<void> renamePlaylist(String oldName, String newName) async {
    final prefs = await SharedPreferences.getInstance();
    final playlists = await getPlaylists();
    if (playlists.containsKey(oldName)) {
      final songs = playlists[oldName]!;
      playlists.remove(oldName);
      playlists[newName] = songs;
      await prefs.setString(_playlistsKey, json.encode(playlists));
    }
  }

  Future<void> mergePlaylists(String playlist1, String playlist2, String newName) async {
    final prefs = await SharedPreferences.getInstance();
    final playlists = await getPlaylists();
    if (playlists.containsKey(playlist1) && playlists.containsKey(playlist2)) {
      final songs1 = playlists[playlist1]!;
      final songs2 = playlists[playlist2]!;
      
      // Merge songs, avoiding duplicates
      final mergedSongs = [...songs1];
      for (var song in songs2) {
        if (!mergedSongs.any((s) => s['id'] == song['id'])) {
          mergedSongs.add(song);
        }
      }
      
      playlists[newName] = mergedSongs;
      await prefs.setString(_playlistsKey, json.encode(playlists));
    }
  }

  Future<void> addToSearchHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getSearchHistory();
    
    // Remove if already exists and add to beginning
    history.removeWhere((q) => q.toLowerCase() == query.toLowerCase());
    history.insert(0, query);
    
    // Keep only last 10 searches
    if (history.length > 10) {
      history.removeLast();
    }
    
    await prefs.setStringList(_searchHistoryKey, history);
  }

  Future<List<String>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_searchHistoryKey) ?? [];
  }

  Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_searchHistoryKey);
  }
} 