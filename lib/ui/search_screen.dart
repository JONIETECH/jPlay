import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jplay/style/appColors.dart';
import 'package:jplay/API/music_api.dart';
import 'package:jplay/widgets/song_tile.dart';
import 'package:jplay/services/playlist_manager.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  SortType _sortBy = SortType.TITLE;
  bool _ascending = true;
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  List<String> _searchHistory = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    _searchHistory = await PlaylistManager.instance.getSearchHistory();
    setState(() {});
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _performSearch();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search songs...',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: Icon(_isSearching ? Icons.clear : Icons.search, color: accent),
              onPressed: () {
                if (_isSearching) {
                  _searchController.clear();
                  setState(() => _results.clear());
                } else {
                  _performSearch();
                }
              },
            ),
          ),
          onSubmitted: (_) => _performSearch(),
        ),
        actions: [
          PopupMenuButton<SortType>(
            icon: Icon(Icons.sort, color: accent),
            color: Color(0xff263238),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: SortType.TITLE,
                child: ListTile(
                  leading: Icon(
                    Icons.sort_by_alpha,
                    color: _sortBy == SortType.TITLE ? accent : Colors.white,
                  ),
                  title: Text(
                    'Sort by Title',
                    style: TextStyle(
                      color: _sortBy == SortType.TITLE ? accent : Colors.white,
                    ),
                  ),
                ),
              ),
              PopupMenuItem(
                value: SortType.ARTIST,
                child: ListTile(
                  leading: Icon(
                    Icons.person,
                    color: _sortBy == SortType.ARTIST ? accent : Colors.white,
                  ),
                  title: Text(
                    'Sort by Artist',
                    style: TextStyle(
                      color: _sortBy == SortType.ARTIST ? accent : Colors.white,
                    ),
                  ),
                ),
              ),
              PopupMenuItem(
                value: SortType.FOLDER,
                child: ListTile(
                  leading: Icon(
                    Icons.folder,
                    color: _sortBy == SortType.FOLDER ? accent : Colors.white,
                  ),
                  title: Text(
                    'Sort by Folder',
                    style: TextStyle(
                      color: _sortBy == SortType.FOLDER ? accent : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
            onSelected: (type) {
              setState(() {
                if (_sortBy == type) {
                  _ascending = !_ascending;
                } else {
                  _sortBy = type;
                  _ascending = true;
                }
              });
              if (_results.isNotEmpty) _performSearch();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _searchController.text.isEmpty
                ? _buildSearchSuggestions()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_searchHistory.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Recent Searches',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                TextButton(
                  child: Text('Clear', style: TextStyle(color: accent)),
                  onPressed: () async {
                    await PlaylistManager.instance.clearSearchHistory();
                    _searchHistory.clear();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchHistory.length,
              itemBuilder: (context, index) {
                final query = _searchHistory[index];
                return ListTile(
                  leading: Icon(Icons.history, color: accent),
                  title: Text(
                    query,
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    _searchController.text = query;
                    _performSearch();
                  },
                );
              },
            ),
          ),
        ] else
          Center(
            child: Text(
              'Search for songs, artists, or folders',
              style: TextStyle(color: Colors.white54),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return _results.isEmpty
        ? Center(
            child: Text(
              _isSearching ? 'No results found' : 'Search for songs',
              style: TextStyle(color: Colors.white54),
            ),
          )
        : ListView.builder(
            itemCount: _results.length,
            itemBuilder: (context, index) => SongTile(song: _results[index]),
          );
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    
    final results = await MusicAPI.searchSongs(
      query,
      sortBy: _sortBy,
      ascending: _ascending,
    );
    
    // Add to search history
    if (results.isNotEmpty) {
      await PlaylistManager.instance.addToSearchHistory(query);
      await _loadSearchHistory();
    }
    
    setState(() {
      _results = results;
      _isSearching = false;
    });
  }
} 