// ignore_for_file: unused_import

import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class MusicAPI {
  static Future<Map<String, dynamic>> _extractMetadata(String filePath) async {
    try {
      // Get title from filename
      final fileName = filePath.split('/').last.replaceAll('.mp3', '');
      
      return {
        'title': fileName,
        'artist': 'Unknown Artist',
        'image': '', // No artwork support for now
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

      return musicFolders;
    } catch (e) {
      print('Error getting music folders: $e');
      return {};
    }
  }

  static Future<void> _scanDirectory(Directory dir, Map<String, List<Map<String, dynamic>>> musicFolders, {required String folderKey, bool recursive = false}) async {
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

  static Future<List<Map<String, dynamic>>> searchSongs(String query, {
    SortType sortBy = SortType.TITLE,
    bool ascending = true,
  }) async {
    final folders = await getMusicByFolders();
    var results = folders.values
      .expand((songs) => songs)
      .where((song) => 
        !song['isDirectory'] && 
        (song['title'].toString().toLowerCase().contains(query.toLowerCase()) ||
        song['artist'].toString().toLowerCase().contains(query.toLowerCase()) ||
        song['folder'].toString().toLowerCase().contains(query.toLowerCase()))
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

  static Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      final permissions = [
        Permission.storage,
        Permission.manageExternalStorage,
      ];

      for (var permission in permissions) {
        if (await permission.status.isDenied) {
          await permission.request();
        }
      }

      final statuses = await Future.wait(
        permissions.map((permission) => permission.status)
      );
      return statuses.every((status) => status.isGranted);
    }
    return true;
  }

  static Future<List<Map<String, dynamic>>> browseDirectory(String path) async {
    try {
      final dir = Directory(path);
      final List<Map<String, dynamic>> contents = [];

      await for (var entity in dir.list(followLinks: false)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
          final metadata = await _extractMetadata(entity.path);
          contents.add({
            'id': entity.path,
            'title': metadata['title'],
            'artist': metadata['artist'],
            'url': entity.path,
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
          'image': '',
        };
      }
      return {};
    } catch (e) {
      print('Error getting song details: $e');
      return {};
    }
  }

  static Future<List<Map<String, dynamic>>> getRecentSongs() async {
    final folders = await getMusicByFolders();
    final allSongs = folders.values
      .expand((songs) => songs)
      .where((song) => !song['isDirectory'])
      .toList();
    return allSongs.take(20).toList();
  }

  static Future<List<Map<String, dynamic>>> getAllSongs() async {
    final folders = await getMusicByFolders();
    return folders.values
      .expand((songs) => songs)
      .where((song) => !song['isDirectory'])
      .toList();
  }
} 

enum SortType { TITLE, ARTIST, FOLDER } 