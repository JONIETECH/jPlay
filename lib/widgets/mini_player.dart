import 'dart:io';
import 'package:flutter/material.dart';
import 'package:jplay/style/appColors.dart';
import 'package:jplay/services/audio_service.dart';
import 'package:jplay/widgets/audio_player.dart';
import 'package:jplay/widgets/play_pause_button.dart';

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
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: song['image']?.isNotEmpty ?? false
                    ? Image.file(
                        File(song['image']),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.music_note, color: accent),
                      )
                    : Icon(Icons.music_note, color: accent),
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
                PlayPauseButton(size: 24, mini: true),
              ],
            ),
          ),
        );
      },
    );
  }
} 