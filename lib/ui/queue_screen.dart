import 'package:flutter/material.dart';
import 'package:jplay/style/appColors.dart';
import 'package:jplay/services/audio_service.dart';
import 'package:jplay/widgets/song_tile.dart';

class QueueScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff384850), Color(0xff263238), Color(0xff263238)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Playing Queue', style: TextStyle(color: accent)),
          actions: [
            StreamBuilder<bool>(
              stream: AudioService.instance.playingStream,
              builder: (context, snapshot) {
                final isShuffled = AudioService.instance.isShuffled;
                return IconButton(
                  icon: Icon(
                    isShuffled ? Icons.shuffle : Icons.shuffle_outlined,
                    color: isShuffled ? accent : Colors.white70,
                  ),
                  onPressed: () {
                    if (isShuffled) {
                      AudioService.instance.unshuffleQueue();
                    } else {
                      AudioService.instance.shuffleQueue();
                    }
                  },
                );
              },
            ),
          ],
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: AudioService.instance.queueStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(accent)));
            }

            final queue = snapshot.data!;
            if (queue.isEmpty) {
              return Center(
                child: Text(
                  'Queue is empty',
                  style: TextStyle(color: Colors.white54),
                ),
              );
            }

            return ReorderableListView.builder(
              itemCount: queue.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
                AudioService.instance.reorderQueue(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final song = queue[index];
                return Dismissible(
                  key: Key(song['id']),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20.0),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    AudioService.instance.removeFromQueue(index);
                  },
                  child: SongTile(
                    song: song,
                    showMenu: false,
                    isPlaying: AudioService.instance.currentSong?['id'] == song['id'],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
} 