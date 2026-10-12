import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;
import '../../model/player_state.dart';
import '../../model/song.dart';

/// Riverpod provider for accessing the singleton DozetoneAudioHandler.
///
/// Overridden in main.dart with the initialized instance from AudioService.init.
final audioHandlerProvider = Provider<DozetoneAudioHandler>((ref) {
  throw UnimplementedError('audioHandlerProvider must be overridden in ProviderScope');
});

/// Background audio handler implementation for Dozetone.
///
/// Owns the just_audio player instance, manages AudioSession interruptions
/// (calls, navigation ducking, headphone unplugging), and syncs playback state
/// with the system media notification and lock screen controls.
class DozetoneAudioHandler extends BaseAudioHandler
    with SeekHandler, QueueHandler {
  final AudioPlayer _player = AudioPlayer();

  List<Song> _rawQueue = <Song>[];
  List<Song> _activeQueue = <Song>[];
  int _currentIndex = -1;
  bool _isShuffle = false;
  PlayerRepeatMode _repeatMode = PlayerRepeatMode.off;

  final StreamController<PlayerState> _playerStateController =
      StreamController<PlayerState>.broadcast();

  /// Stream emitting comprehensive PlayerState updates.
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;

  DozetoneAudioHandler() {
    _initAudioSession();
    _listenToPlayerEvents();
  }

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Headphone disconnect: pause playback automatically
      session.becomingNoisyEventStream.listen((_) {
        pause();
      });

      // Interruption handling (phone calls, alarms)
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(0.5);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              pause();
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(1.0);
              break;
            case AudioInterruptionType.pause:
              play();
              break;
            case AudioInterruptionType.unknown:
              break;
          }
        }
      });
    } catch (e) {
      debugPrint('Error configuring AudioSession: $e');
    }
  }

  void _listenToPlayerEvents() {
    // 1. Map player playback state to AudioService PlaybackState
    _player.playbackEventStream.listen((event) {
      _broadcastPlaybackState();
    });

    // 2. Map position stream
    _player.positionStream.listen((position) {
      _broadcastPlaybackState();
      _emitCurrentState();
    });

    // 3. Handle track completion
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handleTrackCompletion();
      }
    });
  }

  void _broadcastPlaybackState() {
    final playing = _player.playing;
    final processingState = _player.processingState;

    final audioProcessingState = switch (processingState) {
      ProcessingState.idle => AudioProcessingState.idle,
      ProcessingState.loading => AudioProcessingState.loading,
      ProcessingState.buffering => AudioProcessingState.buffering,
      ProcessingState.ready => AudioProcessingState.ready,
      ProcessingState.completed => AudioProcessingState.completed,
    };

    playbackState.add(
      PlaybackState(
        controls: <MediaControl>[
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const <MediaAction>{
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const <int>[0, 1, 2],
        processingState: audioProcessingState,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _currentIndex >= 0 ? _currentIndex : null,
      ),
    );
  }

  void _emitCurrentState() {
    final song = (_currentIndex >= 0 && _currentIndex < _activeQueue.length)
        ? _activeQueue[_currentIndex]
        : null;

    final duration = _player.duration ??
        (song != null ? Duration(milliseconds: song.durationMs) : Duration.zero);

    final state = PlayerState(
      currentSong: song,
      isPlaying: _player.playing,
      isBuffering: _player.processingState == ProcessingState.buffering ||
          _player.processingState == ProcessingState.loading,
      position: _player.position,
      duration: duration,
      isShuffleEnabled: _isShuffle,
      repeatMode: _repeatMode,
      queue: List<Song>.unmodifiable(_activeQueue),
      currentIndex: _currentIndex,
    );

    _playerStateController.add(state);
  }

  void _handleTrackCompletion() {
    if (_repeatMode == PlayerRepeatMode.one) {
      // Repeat current song indefinitely
      _player.seek(Duration.zero);
      _player.play();
      return;
    }

    if (_currentIndex + 1 < _activeQueue.length) {
      // Advance to next song in queue
      skipToNext();
    } else {
      // Reached end of queue
      if (_repeatMode == PlayerRepeatMode.all && _activeQueue.isNotEmpty) {
        // Loop back to start
        _playIndex(0);
      } else {
        // Stop at end, paused, per Section 11.2 requirements
        _player.pause();
        _player.seek(Duration.zero);
        _broadcastPlaybackState();
        _emitCurrentState();
      }
    }
  }

  /// Starts playback of [targetSong] within the given [queue].
  Future<void> playSong(Song targetSong, List<Song> queue) async {
    _rawQueue = List<Song>.from(queue);

    if (_isShuffle) {
      _buildShuffleQueue(targetSong);
    } else {
      _activeQueue = List<Song>.from(_rawQueue);
      _currentIndex = _activeQueue.indexWhere((s) => s.id == targetSong.id);
      if (_currentIndex == -1) _currentIndex = 0;
    }

    await _playIndex(_currentIndex);
  }

  void _buildShuffleQueue(Song firstSong) {
    final remaining = _rawQueue.where((s) => s.id != firstSong.id).toList()
      ..shuffle();
    _activeQueue = <Song>[firstSong, ...remaining];
    _currentIndex = 0;
  }

  Future<void> _playIndex(int index) async {
    if (index < 0 || index >= _activeQueue.length) return;

    _currentIndex = index;
    final song = _activeQueue[_currentIndex];

    // Update system MediaItem for notification
    final item = MediaItem(
      id: song.id.toString(),
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: Duration(milliseconds: song.durationMs),
      artUri: song.dataUri.isNotEmpty ? Uri.file(song.dataUri) : null,
    );
    mediaItem.add(item);

    try {
      await _player.setFilePath(song.dataUri);
      await _player.play();
    } catch (e) {
      debugPrint('Playback error for ${song.title}: $e');
      // Skip to next if broken file per requirements
      if (_currentIndex + 1 < _activeQueue.length) {
        skipToNext();
      }
    }

    _broadcastPlaybackState();
    _emitCurrentState();
  }

  @override
  Future<void> play() async {
    await _player.play();
    _broadcastPlaybackState();
    _emitCurrentState();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _broadcastPlaybackState();
    _emitCurrentState();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _broadcastPlaybackState();
    _emitCurrentState();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _broadcastPlaybackState();
    _emitCurrentState();
  }

  @override
  Future<void> skipToNext() async {
    if (_activeQueue.isEmpty) return;

    if (_currentIndex + 1 < _activeQueue.length) {
      await _playIndex(_currentIndex + 1);
    } else if (_repeatMode == PlayerRepeatMode.all) {
      await _playIndex(0);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_activeQueue.isEmpty) return;

    // Rule: if position > 3 seconds, restart current track
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    if (_currentIndex - 1 >= 0) {
      await _playIndex(_currentIndex - 1);
    } else if (_repeatMode == PlayerRepeatMode.all) {
      await _playIndex(_activeQueue.length - 1);
    } else {
      await _player.seek(Duration.zero);
    }
  }

  /// Toggles shuffle mode on or off.
  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    final currentSong = (_currentIndex >= 0 && _currentIndex < _activeQueue.length)
        ? _activeQueue[_currentIndex]
        : null;

    if (_isShuffle && currentSong != null) {
      _buildShuffleQueue(currentSong);
    } else {
      _activeQueue = List<Song>.from(_rawQueue);
      if (currentSong != null) {
        _currentIndex = _activeQueue.indexWhere((s) => s.id == currentSong.id);
        if (_currentIndex == -1) _currentIndex = 0;
      }
    }
    _emitCurrentState();
  }

  /// Cycles through repeat modes: off -> all -> one -> off.
  void cycleRepeatMode() {
    _repeatMode = switch (_repeatMode) {
      PlayerRepeatMode.off => PlayerRepeatMode.all,
      PlayerRepeatMode.all => PlayerRepeatMode.one,
      PlayerRepeatMode.one => PlayerRepeatMode.off,
    };
    _emitCurrentState();
  }

  /// Sets player volume factor (0.0 to 1.0) for sleep timer fade-out.
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Inserts [song] into the queue to play immediately after the current song.
  void insertNext(Song song) {
    if (_activeQueue.isEmpty) {
      playSong(song, <Song>[song]);
      return;
    }
    final nextIndex = _currentIndex + 1;
    final existingIndex = _activeQueue.indexWhere((s) => s.id == song.id);
    if (existingIndex > _currentIndex) {
      _activeQueue.removeAt(existingIndex);
    }
    _activeQueue.insert(nextIndex.clamp(0, _activeQueue.length), song);
    _emitCurrentState();
  }

  /// Preloads a saved track and position without auto-starting playback.
  Future<void> restoreLastSession({
    required Song song,
    required Duration position,
    required List<Song> queue,
  }) async {
    _rawQueue = List<Song>.from(queue);
    _activeQueue = List<Song>.from(_rawQueue);
    _currentIndex = _activeQueue.indexWhere((s) => s.id == song.id);
    if (_currentIndex == -1) {
      _activeQueue.insert(0, song);
      _currentIndex = 0;
    }

    final item = MediaItem(
      id: song.id.toString(),
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: Duration(milliseconds: song.durationMs),
      artUri: song.dataUri.isNotEmpty ? Uri.file(song.dataUri) : null,
    );
    mediaItem.add(item);

    // Immediately emit restored state so UI (MiniPlayer) renders without waiting for file I/O
    final restoredState = PlayerState(
      currentSong: song,
      isPlaying: false,
      position: position,
      duration: Duration(milliseconds: song.durationMs),
      queue: List<Song>.unmodifiable(_activeQueue),
      currentIndex: _currentIndex,
      isShuffleEnabled: _isShuffle,
      repeatMode: _repeatMode,
    );
    _playerStateController.add(restoredState);
    _broadcastPlaybackState();

    try {
      await _player.setFilePath(song.dataUri);
      await _player.seek(position);
    } catch (_) {
    }

    _broadcastPlaybackState();
    _emitCurrentState();
  }

  /// Adds [song] to the end of the active playback queue.
  void addToQueue(Song song) {
    if (_activeQueue.isEmpty) {
      playSong(song, <Song>[song]);
      return;
    }
    _rawQueue.add(song);
    _activeQueue.add(song);
    _emitCurrentState();
  }

  /// Removes a song from playback and queue when deleted from device storage.
  Future<void> removeSongFromPlayback(int songId) async {
    final wasCurrentlyPlaying = (_currentIndex >= 0 &&
        _currentIndex < _activeQueue.length &&
        _activeQueue[_currentIndex].id == songId);

    _rawQueue.removeWhere((s) => s.id == songId);
    final removedIndex = _activeQueue.indexWhere((s) => s.id == songId);
    if (removedIndex != -1) {
      _activeQueue.removeAt(removedIndex);
    }

    if (_activeQueue.isEmpty) {
      _currentIndex = -1;
      await _player.stop();
      mediaItem.add(null);
      _broadcastPlaybackState();
      _emitCurrentState();
      return;
    }

    if (wasCurrentlyPlaying) {
      if (_currentIndex >= _activeQueue.length) {
        _currentIndex = 0;
      }
      await _playIndex(_currentIndex);
    } else {
      if (removedIndex != -1 && removedIndex < _currentIndex) {
        _currentIndex--;
      }
      _emitCurrentState();
    }
  }

  /// Disposes internal resources when app terminates.
  Future<void> dispose() async {
    await _playerStateController.close();
    await _player.dispose();
  }
}
