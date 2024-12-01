import 'package:flutter/material.dart';
import 'package:jplay/services/audio_service.dart';
import 'package:jplay/style/appColors.dart';
import 'package:jplay/ui/homePage.dart';
import 'package:jplay/ui/library_screen.dart';
import 'package:jplay/ui/playlists_screen.dart';
import 'package:jplay/widgets/mini_player.dart';
import 'package:just_audio/just_audio.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final _pages = [
    Jplay(),
    LibraryScreen(),
    PlaylistsScreen(),
  ];

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
        body: Stack(
          children: [
            // Main content
            IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
            
            // Mini player positioned at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: kBottomNavigationBarHeight,
              child: StreamBuilder<Map<String, dynamic>>(
                stream: AudioService.instance.currentSongStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return SizedBox.shrink();
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MiniPlayer(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: accent,
          unselectedItemColor: Colors.white54,
          backgroundColor: Color(0xff263238),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.folder),
              label: 'Browse',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_music),
              label: 'Library',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.playlist_play),
              label: 'Playlists',
            ),
          ],
        ),
      ),
    );
  }
} 