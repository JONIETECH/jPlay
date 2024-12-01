import 'package:flutter/material.dart';
import 'package:jplay/style/appColors.dart';
import 'package:jplay/services/audio_service.dart' show AudioService, RepeatMode;
import 'package:jplay/services/playlist_manager.dart';
import 'dart:io';
import 'package:jplay/widgets/play_pause_button.dart';
import 'package:jplay/widgets/music_thumbnail.dart';

class AudioPlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;
  final String artist;
  final String thumbnail;

  const AudioPlayerScreen({
    required this.videoId,
    required this.title,
    required this.artist,
    required this.thumbnail,
  });

  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  bool _isFavorite = false;
  bool _isShuffled = false;
  late Map<String, dynamic> _currentSong;

  @override
  void initState() {
    super.initState();
    _currentSong = {
      'id': widget.videoId,
      'title': widget.title,
      'artist': widget.artist,
      'image': widget.thumbnail,
    };
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final favorites = await PlaylistManager.instance.getFavorites();
    setState(() {
      _isFavorite = favorites.any((s) => s['id'] == widget.videoId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: AudioService.instance.currentSongStream,
      initialData: _currentSong,
      builder: (context, snapshot) {
        final song = snapshot.data!;
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
              leading: IconButton(
                icon: Icon(Icons.keyboard_arrow_down, color: accent),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: accent),
                  onPressed: () async {
                    final song = {
                      'id': widget.videoId,
                      'title': widget.title,
                      'artist': widget.artist,
                      'url': widget.thumbnail,
                    };
                    await PlaylistManager.instance.addToFavorites(song);
                    setState(() => _isFavorite = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added to favorites'), backgroundColor: accent),
                    );
                  },
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: accent),
                  color: Color(0xff263238),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'playlist',
                      child: ListTile(
                        leading: Icon(Icons.playlist_add, color: accent),
                        title: Text('Add to Playlist', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'playlist') {
                      // Show add to playlist dialog
                    }
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Album Art
                      MusicThumbnail(
                        size: MediaQuery.of(context).size.width * 0.8,
                        iconSize: 80,
                        borderRadius: 20,
                      ),
                      SizedBox(height: 40),
                      // Title and Artist
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            Text(
                              song['title'] ?? '',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Text(
                              song['artist'] ?? 'Unknown Artist',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Progress Bar
                StreamBuilder<Duration>(
                  stream: AudioService.instance.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = AudioService.instance.duration ?? Duration.zero;
                    return Column(
                      children: [
                        Slider(
                          value: position.inSeconds.toDouble(),
                          max: duration.inSeconds.toDouble(),
                          activeColor: accent,
                          inactiveColor: Colors.white24,
                          onChanged: (value) {
                            AudioService.instance.seek(Duration(seconds: value.toInt()));
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                // Controls
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isShuffled ? Icons.shuffle : Icons.shuffle_outlined,
                          color: _isShuffled ? accent : Colors.white70,
                        ),
                        onPressed: () {
                          setState(() => _isShuffled = !_isShuffled);
                          if (_isShuffled) {
                            AudioService.instance.shuffleQueue();
                          } else {
                            AudioService.instance.unshuffleQueue();
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.skip_previous, color: Colors.white),
                        iconSize: 40,
                        onPressed: () => AudioService.instance.playPrevious(),
                      ),
                      PlayPauseButton(size: 80),
                      IconButton(
                        icon: Icon(Icons.skip_next, color: Colors.white),
                        iconSize: 40,
                        onPressed: () => AudioService.instance.playNext(),
                      ),
                      IconButton(
                        icon: Icon(
                          _getRepeatIcon(),
                          color: AudioService.instance.repeatMode != RepeatMode.none 
                            ? accent 
                            : Colors.white70,
                        ),
                        onPressed: () {
                          AudioService.instance.cycleRepeatMode();
                          setState(() {}); // Refresh UI
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  IconData _getRepeatIcon() {
    switch (AudioService.instance.repeatMode) {
      case RepeatMode.none:
        return Icons.repeat;
      case RepeatMode.all:
        return Icons.repeat;
      case RepeatMode.one:
        return Icons.repeat_one;
    }
  }
} 