import 'package:flutter/material.dart';
import 'package:jplay/style/appColors.dart';
import 'package:jplay/services/playlist_manager.dart';
import 'package:jplay/ui/playlist_details_screen.dart';

class PlaylistsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Playlists', style: TextStyle(color: accent)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: accent),
            onPressed: () => _showCreatePlaylistDialog(context),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: accent),
            color: Color(0xff263238),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'merge',
                child: ListTile(
                  leading: Icon(Icons.merge_type, color: accent),
                  title: Text('Merge Playlists', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'merge') {
                _showMergeDialog(context);
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: PlaylistManager.instance.getPlaylists(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(accent)));
          }

          final playlists = snapshot.data!;
          if (playlists.isEmpty) {
            return Center(
              child: Text(
                'No playlists yet\nTap + to create one',
                style: TextStyle(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final name = playlists.keys.elementAt(index);
              final songs = playlists[name]!;
              return ListTile(
                leading: Icon(Icons.playlist_play, color: accent, size: 40),
                title: Text(name, style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  '${songs.length} songs',
                  style: TextStyle(color: accentLight),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlaylistDetailsScreen(
                        name: name,
                        songs: songs,
                      ),
                    ),
                  );
                },
                onLongPress: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Color(0xff263238),
                    builder: (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Icon(Icons.edit, color: accent),
                          title: Text('Rename', style: TextStyle(color: Colors.white)),
                          onTap: () {
                            Navigator.pop(context);
                            _showRenameDialog(context, name);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xff263238),
        title: Text('Create Playlist', style: TextStyle(color: accent)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Playlist Name',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: accent),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: accent)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Create', style: TextStyle(color: accent)),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await PlaylistManager.instance.createPlaylist(name);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showMergeDialog(BuildContext context) {
    String? playlist1;
    String? playlist2;
    final newNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Color(0xff263238),
          title: Text('Merge Playlists', style: TextStyle(color: accent)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
                future: PlaylistManager.instance.getPlaylists(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();
                  final playlists = snapshot.data!.keys.toList();
                  
                  return Column(
                    children: [
                      // First playlist dropdown
                      DropdownButtonFormField<String>(
                        value: playlist1,
                        dropdownColor: Color(0xff263238),
                        decoration: InputDecoration(
                          labelText: 'First Playlist',
                          labelStyle: TextStyle(color: accent),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: accent),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        items: playlists.map((name) => DropdownMenuItem(
                          value: name,
                          child: Text(name),
                        )).toList(),
                        onChanged: (value) => setState(() => playlist1 = value),
                      ),
                      SizedBox(height: 16),
                      // Second playlist dropdown
                      DropdownButtonFormField<String>(
                        value: playlist2,
                        dropdownColor: Color(0xff263238),
                        decoration: InputDecoration(
                          labelText: 'Second Playlist',
                          labelStyle: TextStyle(color: accent),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: accent),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        items: playlists.map((name) => DropdownMenuItem(
                          value: name,
                          child: Text(name),
                        )).toList(),
                        onChanged: (value) => setState(() => playlist2 = value),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 16),
              // New playlist name
              TextField(
                controller: newNameController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'New Playlist Name',
                  labelStyle: TextStyle(color: accent),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: accent),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: accent),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: accent)),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('Merge', style: TextStyle(color: accent)),
              onPressed: () async {
                final newName = newNameController.text.trim();
                if (playlist1 != null && playlist2 != null && newName.isNotEmpty) {
                  await PlaylistManager.instance.mergePlaylists(
                    playlist1!,
                    playlist2!,
                    newName,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Playlists merged'),
                      backgroundColor: accent,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, String name) {
    final controller = TextEditingController();
    controller.text = name;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xff263238),
        title: Text('Rename Playlist', style: TextStyle(color: accent)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Playlist Name',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: accent),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: accent)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Rename', style: TextStyle(color: accent)),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await PlaylistManager.instance.renamePlaylist(name, newName);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
} 