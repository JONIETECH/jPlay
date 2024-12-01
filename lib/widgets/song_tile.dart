import 'dart:io';
import 'package:flutter/material.dart';
import 'package:jplay/style/appColors.dart';
import 'package:jplay/services/audio_service.dart';
import 'package:jplay/services/playlist_manager.dart';

class SongTile extends StatelessWidget {
  final Map<String, dynamic> song;
  final VoidCallback? onPlay;
  final bool showMenu;
  final bool isPlaying;

  const SongTile({
    required this.song,
    this.onPlay,
    this.showMenu = true,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.music_note, color: accent),
      title: Text(
        song['title'] ?? '',
        style: TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        song['artist'] ?? 'Unknown Artist',
        style: TextStyle(color: accentLight),
      ),
      onTap: () {
        if (onPlay != null) {
          onPlay!();
        } else {
          AudioService.instance.playSong(song);
          PlaylistManager.instance.addToRecentlyPlayed(song);
        }
      },
      trailing: showMenu ? PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: accent),
        color: Color(0xff263238),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'favorite',
            child: ListTile(
              leading: Icon(Icons.favorite_border, color: accent),
              title: Text('Add to Favorites', style: TextStyle(color: Colors.white)),
            ),
          ),
          PopupMenuItem(
            value: 'playlist',
            child: ListTile(
              leading: Icon(Icons.playlist_add, color: accent),
              title: Text('Add to Playlist', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
        onSelected: (value) async {
          if (value == 'favorite') {
            await PlaylistManager.instance.addToFavorites(song);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added to Favorites'),
                backgroundColor: accent,
              ),
            );
          } else if (value == 'playlist') {
            showDialog(
              context: context,
              builder: (context) => AddToPlaylistDialog(song: song),
            );
          }
        },
      ) : null,
    );
  }
}

class AddToPlaylistDialog extends StatefulWidget {
  final Map<String, dynamic> song;

  const AddToPlaylistDialog({required this.song});

  @override
  _AddToPlaylistDialogState createState() => _AddToPlaylistDialogState();
}

class _AddToPlaylistDialogState extends State<AddToPlaylistDialog> {
  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xff263238),
      title: Text('Add to Playlist', style: TextStyle(color: accent)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _textController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'New Playlist Name',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: accent),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: accent),
              ),
            ),
          ),
          SizedBox(height: 20),
          FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
            future: PlaylistManager.instance.getPlaylists(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return CircularProgressIndicator();
              final playlists = snapshot.data!;
              if (playlists.isEmpty) {
                return Text(
                  'No playlists yet',
                  style: TextStyle(color: Colors.white54),
                );
              }
              return Column(
                children: playlists.keys.map((name) => ListTile(
                  title: Text(name, style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    await PlaylistManager.instance.addToPlaylist(name, widget.song);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added to $name'),
                        backgroundColor: accent,
                      ),
                    );
                  },
                )).toList(),
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text('Cancel', style: TextStyle(color: accent)),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          child: Text('Create New', style: TextStyle(color: accent)),
          onPressed: () async {
            final name = _textController.text.trim();
            if (name.isNotEmpty) {
              await PlaylistManager.instance.createPlaylist(name);
              await PlaylistManager.instance.addToPlaylist(name, widget.song);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added to $name'),
                  backgroundColor: accent,
                ),
              );
            }
          },
        ),
      ],
    );
  }
} 