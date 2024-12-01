import 'package:flutter/material.dart';
import 'package:jplay/style/appColors.dart';

class MusicThumbnail extends StatelessWidget {
  final double size;
  final double iconSize;
  final double borderRadius;

  const MusicThumbnail({
    this.size = 60,
    this.iconSize = 24,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        Icons.music_note,
        color: accent,
        size: iconSize,
      ),
    );
  }
} 