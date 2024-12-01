import 'package:flutter/material.dart';
import 'package:jplay/API/music_api.dart';
import 'package:jplay/style/appColors.dart';
import 'package:jplay/services/playlist_manager.dart';
import 'package:jplay/widgets/song_tile.dart';

class LibraryScreen extends StatefulWidget {
  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Library', style: TextStyle(color: accent)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accent,
          labelColor: accent,
          unselectedLabelColor: Colors.white54,
          tabs: [
            Tab(text: 'Recent'),
            Tab(text: 'Favorites'),
            Tab(text: 'All Songs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RecentTab(),
          FavoritesTab(),
          AllSongsTab(),
        ],
      ),
    );
  }
}

class RecentTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: PlaylistManager.instance.getRecentlyPlayed(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(accent)));
        }

        final songs = snapshot.data!;
        if (songs.isEmpty) {
          return Center(
            child: Text(
              'No recently played songs',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) => SongTile(song: songs[index]),
        );
      },
    );
  }
}

class FavoritesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: PlaylistManager.instance.getFavorites(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(accent)));
        }

        final songs = snapshot.data!;
        if (songs.isEmpty) {
          return Center(
            child: Text(
              'No favorite songs yet',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) => SongTile(
            song: songs[index],
            showMenu: false,
          ),
        );
      },
    );
  }
}

class AllSongsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: MusicAPI.getMusicByFolders(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(accent)));
        }

        final folders = snapshot.data!;
        final allSongs = folders.values
            .expand((songs) => songs)
            .where((song) => !(song['isDirectory'] ?? false))
            .toList();

        if (allSongs.isEmpty) {
          return Center(
            child: Text(
              'No songs found',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return ListView.builder(
          itemCount: allSongs.length,
          itemBuilder: (context, index) => SongTile(song: allSongs[index]),
        );
      },
    );
  }
} 