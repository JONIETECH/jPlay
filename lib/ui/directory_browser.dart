import 'package:flutter/material.dart';
import 'package:jplay/API/music_api.dart';
import 'package:jplay/style/appColors.dart';
import 'package:jplay/widgets/audio_player.dart';

class DirectoryBrowser extends StatefulWidget {
  final String path;
  final String title;

  const DirectoryBrowser({
    required this.path,
    required this.title,
  });

  @override
  _DirectoryBrowserState createState() => _DirectoryBrowserState();
}

class _DirectoryBrowserState extends State<DirectoryBrowser> {
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
          title: Text(widget.title, style: TextStyle(color: accent)),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: accent),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: MusicAPI.browseDirectory(widget.path),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final items = snapshot.data!;
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    'Empty folder',
                    style: TextStyle(color: accent),
                  ),
                );
              }

              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isDirectory = item['isDirectory'] ?? false;

                  return ListTile(
                    leading: Icon(
                      isDirectory ? Icons.folder : Icons.music_note,
                      color: accent,
                    ),
                    title: Text(
                      item['title'] ?? '',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: !isDirectory
                        ? Text(
                            item['artist'] ?? 'Unknown Artist',
                            style: TextStyle(color: accentLight),
                          )
                        : null,
                    onTap: () {
                      if (isDirectory) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DirectoryBrowser(
                              path: item['id'],
                              title: item['title'],
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AudioPlayerScreen(
                              videoId: item['id'],
                              title: item['title'],
                              artist: item['artist'] ?? 'Unknown Artist',
                              thumbnail: item['image'] ?? '',
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            }
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            );
          },
        ),
      ),
    );
  }
} 