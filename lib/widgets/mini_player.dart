import 'dart:io';
import 'package:flutter/material.dart';
import 'package:jplay/style/appColors.dart';
import 'package:jplay/services/audio_service.dart';
import 'package:jplay/widgets/audio_player.dart';

class MiniPlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: AudioService.instance.currentSongStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox.shrink();
        
        final song = snapshot.data!;
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AudioPlayerScreen(
                  videoId: song['id'],
                  title: song['title'],
                  artist: song['artist'],
                  thumbnail: song['image'],
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
            child: Row(
              children: [
                if (song['image']?.isNotEmpty ?? false)
                  Image.file(
                    File(song['image']),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song['title'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          song['artist'],
                          style: TextStyle(
                            color: accentLight,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                StreamBuilder<bool>(
                  stream: AudioService.instance.playingStream,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data ?? false;
                    return IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: accent,
                      ),
                      onPressed: () {
                        if (isPlaying) {
                          AudioService.instance.pause();
                        } else {
                          AudioService.instance.play();
                        }
                      },
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