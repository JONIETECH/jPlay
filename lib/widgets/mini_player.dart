import 'dart:io';
import 'package:flutter/material.dart';
import 'package:jplay/style/appColors.dart';
import 'package:jplay/services/audio_service.dart';
import 'package:jplay/widgets/audio_player.dart';
import 'package:jplay/widgets/play_pause_button.dart';
import 'package:jplay/widgets/music_thumbnail.dart';

class MiniPlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: AudioService.instance.currentSongStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) return SizedBox.shrink();
        
        final song = snapshot.data!;
        if (song['title'] == null || song['artist'] == null) return SizedBox.shrink();
        
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AudioPlayerScreen(
                  videoId: song['id'] ?? '',
                  title: song['title'] ?? '',
                  artist: song['artist'] ?? 'Unknown Artist',
                  thumbnail: song['image'] ?? '',
                ),
              ),
            );
          },
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Color(0xff263238),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      MusicThumbnail(),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(song['title'], style: TextStyle(color: Colors.white, fontSize: 16)),
                              Text(song['artist'], style: TextStyle(color: accentLight, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                      PlayPauseButton(size: 24, mini: true),
                    ],
                  ),
                ),
                // Progress Bar
                StreamBuilder<Duration>(
                  stream: AudioService.instance.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = AudioService.instance.duration ?? Duration.zero;
                    return LinearProgressIndicator(
                      value: duration.inSeconds > 0 ? position.inSeconds / duration.inSeconds : 0,
                      backgroundColor: Colors.grey[800],
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                      minHeight: 2,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 