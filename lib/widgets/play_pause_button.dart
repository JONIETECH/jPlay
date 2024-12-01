import 'package:flutter/material.dart';
import 'package:jplay/style/appColors.dart';
import 'package:jplay/services/audio_service.dart';

class PlayPauseButton extends StatelessWidget {
  final double size;
  final bool mini;

  const PlayPauseButton({
    this.size = 24,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: AudioService.instance.playingStream,
      initialData: false,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        return IconButton(
          icon: Icon(
            isPlaying 
              ? (mini ? Icons.pause : Icons.pause_circle_filled)
              : (mini ? Icons.play_arrow : Icons.play_circle_fill),
            color: accent,
          ),
          iconSize: size,
          onPressed: () async {
            if (isPlaying) {
              await AudioService.instance.pause();
            } else {
              await AudioService.instance.play();
            }
          },
        );
      },
    );
  }
} 