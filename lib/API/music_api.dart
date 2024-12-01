// ignore_for_file: unused_import

import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:on_audio_query/on_audio_query.dart';

class MusicAPI {
  static final OnAudioQuery _audioQuery = OnAudioQuery();

  static Future<Map<String, List<Map<String, dynamic>>>> getMusicByFolders() async {
    if (!await _requestPermission()) return {};

    try {
      final Map<String, List<Map<String, dynamic>>> musicFolders = {};
      
      // Common music directories
      final commonDirs = [
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Downloads',
      ];

      // Add internal storage root
      musicFolders['Internal Storage'] = [];
      final internalDir = Directory('/storage/emulated/0');
      if (await internalDir.exists()) {
        await _scanDirectory(internalDir, musicFolders, folderKey: 'Internal Storage', recursive: false);
      }

      // Add common directories
      for (var path in commonDirs) {
        final dir = Directory(path);
        if (await dir.exists()) {
          final folderName = path.split('/').last;
          musicFolders[folderName] = [];
          await _scanDirectory(dir, musicFolders, folderKey: folderName, recursive: false);
        }
      }

      // Try to add SD card if present
      try {
        final List<Directory>? externalDirs = await getExternalStorageDirectories();
        if (externalDirs != null && externalDirs.length > 1) {
          // The second directory is usually the SD card
          musicFolders['SD Card'] = [];
          await _scanDirectory(externalDirs[1], musicFolders, folderKey: 'SD Card', recursive: false);
        }
      } catch (e) {
        print('Error accessing SD card: $e');
      }

      // Remove empty folders
      musicFolders.removeWhere((_, songs) => songs.isEmpty);
      
      return musicFolders;
    } catch (e) {
      print('Error getting music folders: $e');
      return {};
    }
  }

  static Future<void> _scanDirectory(
    Directory dir, 
    Map<String, List<Map<String, dynamic>>> musicFolders,
    {required String folderKey, bool recursive = false}
  ) async {
    try {
      await for (var entity in dir.list(recursive: recursive, followLinks: false)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
          final filePath = entity.absolute.path;
          final metadata = await _extractMetadata(filePath);
          
          musicFolders[folderKey]!.add({
            'id': filePath,
            'title': metadata['title'],
            'artist': metadata['artist'],
            'url': filePath,
            'image': metadata['image'],
            'folder': folderKey,
            'isDirectory': false,
          });
        } else if (entity is Directory && !recursive) {
          musicFolders[folderKey]!.add({
            'id': entity.absolute.path,
            'title': entity.path.split('/').last,
            'isDirectory': true,
          });
        }
      }
    } catch (e) {
      print('Error scanning directory ${dir.path}: $e');
    }
  }

  static Future<Map<String, dynamic>> _extractMetadata(String filePath) async {
    try {
      // Get song ID from path
      final songId = int.tryParse(filePath.split('/').last.split('.').first) ?? 0;
      
      // Get artwork
      final artwork = await _audioQuery.queryArtwork(
        songId,
        ArtworkType.AUDIO,
        size: 500,
        quality: 100,
      );
      
      // Get title from filename
      final fileName = filePath.split('/').last.replaceAll('.mp3', '');
      
      return {
        'title': fileName,
        'artist': 'Unknown Artist',
        'image': artwork != null ? await _saveArtwork(artwork, filePath) : '',
      };
    } catch (e) {
      print('Error extracting metadata: $e');
      return {
        'title': filePath.split('/').last.replaceAll('.mp3', ''),
        'artist': 'Unknown Artist',
        'image': '',
      };
    }
  }

  static Future<String> _saveArtwork(Uint8List artwork, String songPath) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final fileName = songPath.split('/').last.replaceAll('.mp3', '_cover.jpg');
      final file = File('${cacheDir.path}/$fileName');
      await file.writeAsBytes(artwork);
      return file.path;
    } catch (e) {
      print('Error saving artwork: $e');
      return '';
    }
  }

  // Add method to browse a specific directory
  static Future<List<Map<String, dynamic>>> browseDirectory(String path) async {
    try {
      final dir = Directory(path);
      final List<Map<String, dynamic>> contents = [];

      await for (var entity in dir.list(followLinks: false)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
          contents.add({
            'id': entity.path,
            'title': entity.path.split('/').last.replaceAll('.mp3', ''),
            'artist': 'Unknown Artist',
            'url': entity.path,
            'image': '',
            'isDirectory': false,
          });
        } else if (entity is Directory) {
          contents.add({
            'id': entity.path,
            'title': entity.path.split('/').last,
            'isDirectory': true,
          });
        }
      }

      return contents;
    } catch (e) {
      print('Error browsing directory $path: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> searchSongs(String query, {
    SortType sortBy = SortType.TITLE,
    bool ascending = true,
  }) async {
    final songs = await getAllSongs();
    var results = songs.where((song) => 
      song['title'].toString().toLowerCase().contains(query.toLowerCase()) ||
      song['artist'].toString().toLowerCase().contains(query.toLowerCase()) ||
      song['folder'].toString().toLowerCase().contains(query.toLowerCase())
    ).toList();

    switch (sortBy) {
      case SortType.TITLE:
        results.sort((a, b) => ascending ? 
          a['title'].toString().compareTo(b['title'].toString()) :
          b['title'].toString().compareTo(a['title'].toString()));
        break;
      case SortType.ARTIST:
        results.sort((a, b) => ascending ?
          a['artist'].toString().compareTo(b['artist'].toString()) :
          b['artist'].toString().compareTo(a['artist'].toString()));
        break;
      case SortType.FOLDER:
        results.sort((a, b) => ascending ?
          a['folder'].toString().compareTo(b['folder'].toString()) :
          b['folder'].toString().compareTo(a['folder'].toString()));
        break;
    }

    return results;
  }

  static Future<Map<String, dynamic>> getSongDetails(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final filePath = file.absolute.path;
        final metadata = await _extractMetadata(filePath);
        
        return {
          'id': filePath,
          'title': metadata['title'],
          'artist': metadata['artist'],
          'url': filePath,
          'image': metadata['image'],
        };
      }
      print('File does not exist: $path');
      return {};
    } catch (e) {
      print('Error getting song details: $e');
      return {};
    }
  }

  static Future<List<Map<String, dynamic>>> getRecentSongs() async {
    final folders = await getMusicByFolders();
    final allSongs = folders.values.expand((songs) => songs).toList();
    return allSongs.take(20).toList();
  }

  static Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      final permissions = [
        Permission.storage,
        Permission.manageExternalStorage,
        Permission.mediaLibrary,
      ];

      // Request each permission
      for (var permission in permissions) {
        if (await permission.status.isDenied) {
          await permission.request();
        }
      }

      // Check if all permissions are granted
      final statuses = await Future.wait(
        permissions.map((permission) => permission.status)
      );
      return statuses.every((status) => status.isGranted);
    }
    return true;
  }

  static Future<List<Map<String, dynamic>>> getAllSongs() async {
    final folders = await getMusicByFolders();
    final allSongs = folders.values.expand((songs) => songs).toList();
    return allSongs;
  }
}

enum SortType { TITLE, ARTIST, FOLDER } 