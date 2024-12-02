// ignore_for_file: unused_import

import 'dart:async';
import 'dart:math';
import 'package:just_audio/just_audio.dart';
import 'package:jplay/services/playlist_manager.dart';

enum RepeatMode { none, all, one }

class AudioService {
  static final AudioService instance = AudioService._internal();
  AudioService._internal();

  final _player = AudioPlayer();
  final _currentSongController = StreamController<Map<String, dynamic>>.broadcast();
  final _playingController = StreamController<bool>.broadcast();
  final _queueController = StreamController<List<Map<String, dynamic>>>.broadcast();
  
  Map<String, dynamic>? _currentSong;
  List<Map<String, dynamic>> _queue = [];
  bool _isShuffled = false;
  List<Map<String, dynamic>> _originalQueue = [];

  Stream<Map<String, dynamic>> get currentSongStream => _currentSongController.stream;
  Stream<bool> get playingStream => _playingController.stream;
  Stream<List<Map<String, dynamic>>> get queueStream => _queueController.stream;
  Map<String, dynamic>? get currentSong => _currentSong;
  List<Map<String, dynamic>> get queue => _queue;
  bool get isShuffled => _isShuffled;

  Future<void> playPlaylist(List<Map<String, dynamic>> songs, {bool shuffle = false}) async {
    _queue = List.from(songs);
    _originalQueue = List.from(songs);
    if (shuffle) {
      _shuffleQueue();
    }
    _queueController.add(_queue);
    if (_queue.isNotEmpty) {
      await playSong(_queue.first);
    }
  }

  void _shuffleQueue() {
    _isShuffled = true;
    final current = _queue.removeAt(0); // Keep current song at top
    _queue.shuffle();
    _queue.insert(0, current);
    _queueController.add(_queue);
  }

  void unshuffleQueue() {
    _isShuffled = false;
    _queue = List.from(_originalQueue);
    if (_currentSong != null) {
      final currentIndex = _queue.indexWhere((s) => s['id'] == _currentSong!['id']);
      if (currentIndex != -1) {
        _queue.removeAt(currentIndex);
        _queue.insert(0, _currentSong!);
      }
    }
    _queueController.add(_queue);
  }

  Future<void> playSong(Map<String, dynamic> song) async {
    try {
      _currentSong = song;
      _currentSongController.add(song);

      await _player.setFilePath(song['url']);
      await PlaylistManager.instance.addToRecentlyPlayed(song);
      await play();

      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (_repeatMode == RepeatMode.one) {
            _player.seek(Duration.zero);
            play();
          } else {
            playNext();
          }
        }
      });
    } catch (e) {
      print('Error playing song: $e');
      _currentSong = null;
      _currentSongController.add({});
    }
  }

  Future<void> playNext() async {
    if (_queue.isEmpty) return;
    final currentIndex = _queue.indexWhere((s) => s['id'] == _currentSong?['id']);
    
    if (currentIndex < _queue.length - 1) {
      await playSong(_queue[currentIndex + 1]);
    } else if (_repeatMode == RepeatMode.all && _queue.isNotEmpty) {
      await playSong(_queue[0]);
    }
  }

  Future<void> playPrevious() async {
    if (_queue.isEmpty) return;
    final currentIndex = _queue.indexWhere((s) => s['id'] == _currentSong?['id']);
    
    if (currentIndex > 0) {
      await playSong(_queue[currentIndex - 1]);
    } else if (_repeatMode == RepeatMode.all && _queue.isNotEmpty) {
      await playSong(_queue.last);
    }
  }

  Future<void> play() async {
    try {
      await _player.play();
      _playingController.add(true);
    } catch (e) {
      print('Error playing: $e');
      _playingController.add(false);
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
      _playingController.add(false);
    } catch (e) {
      print('Error pausing: $e');
      _playingController.add(true);
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _playingController.add(false);
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void dispose() {
    _player.dispose();
    _currentSongController.close();
    _playingController.close();
    _queueController.close();
  }

  Future<void> shuffleQueue() async {
    _shuffleQueue();
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, item);
    _queueController.add(_queue);
  }

  Future<void> removeFromQueue(int index) async {
    _queue.removeAt(index);
    _queueController.add(_queue);
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Duration? get duration => _player.duration;

  RepeatMode _repeatMode = RepeatMode.none;
  RepeatMode get repeatMode => _repeatMode;

  void cycleRepeatMode() {
    switch (_repeatMode) {
      case RepeatMode.none:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.none;
        break;
    }
  }
} 