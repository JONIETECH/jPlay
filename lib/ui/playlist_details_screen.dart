import 'package:flutter/material.dart';
import 'package:jplay/style/appColors.dart';
import 'package:jplay/services/playlist_manager.dart';
import 'package:jplay/widgets/song_tile.dart';
import 'package:jplay/services/audio_service.dart';

class PlaylistDetailsScreen extends StatefulWidget {
  final String name;
  final List<Map<String, dynamic>> songs;

  const PlaylistDetailsScreen({
    required this.name,
    required this.songs,
  });

  @override
  _PlaylistDetailsScreenState createState() => _PlaylistDetailsScreenState();
}

class _PlaylistDetailsScreenState extends State<PlaylistDetailsScreen> {
  late List<Map<String, dynamic>> _songs;

  @override
  void initState() {
    super.initState();
    _songs = List.from(widget.songs);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xff384850),
            Color(0xff263238),
            Color(0xff263238),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(widget.name, style: TextStyle(color: accent)),
          actions: [
            IconButton(
              icon: Icon(Icons.delete_outline, color: accent),
              onPressed: () => _showDeleteDialog(context),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(Icons.playlist_play, color: accent, size: 72),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${_songs.length} songs',
                          style: TextStyle(color: accentLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_songs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                      ),
                      icon: Icon(Icons.play_arrow),
                      label: Text('Play All'),
                      onPressed: () {
                        AudioService.instance.playPlaylist(_songs);
                      },
                    ),
                    SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white24,
                        foregroundColor: Colors.white,
                      ),
                      icon: Icon(Icons.shuffle),
                      label: Text('Shuffle'),
                      onPressed: () {
                        AudioService.instance.playPlaylist(_songs, shuffle: true);
                      },
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _songs.isEmpty
                ? Center(
                    child: Text(
                      'No songs in playlist\nTap + to add songs',
                      style: TextStyle(color: Colors.white54),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ReorderableListView.builder(
                    itemCount: _songs.length,
                    onReorder: (oldIndex, newIndex) async {
                      setState(() {
                        if (newIndex > oldIndex) {
                          newIndex -= 1;
                        }
                        final item = _songs.removeAt(oldIndex);
                        _songs.insert(newIndex, item);
                      });
                      await PlaylistManager.instance.reorderPlaylist(
                        widget.name, 
                        oldIndex, 
                        newIndex
                      );
                    },
                    itemBuilder: (context, index) {
                      final song = _songs[index];
                      return Dismissible(
                        key: Key(song['id']),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20.0),
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) async {
                          setState(() {
                            _songs.removeAt(index);
                          });
                          await PlaylistManager.instance.removeFromPlaylist(
                            widget.name,
                            song['id'],
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Removed from playlist'),
                              backgroundColor: accent,
                              action: SnackBarAction(
                                label: 'UNDO',
                                textColor: Colors.black,
                                onPressed: () async {
                                  setState(() {
                                    _songs.insert(index, song);
                                  });
                                  await PlaylistManager.instance.addToPlaylist(
                                    widget.name,
                                    song,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        child: SongTile(song: song),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xff263238),
        title: Text('Delete Playlist', style: TextStyle(color: accent)),
        content: Text(
          'Are you sure you want to delete this playlist?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: accent)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await PlaylistManager.instance.deletePlaylist(widget.name);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to playlists screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Playlist deleted'),
                  backgroundColor: accent,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 