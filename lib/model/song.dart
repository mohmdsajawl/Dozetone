import 'package:flutter/foundation.dart';

/// Immutable domain model representing a local audio track.
///
/// Follows MVVM architecture rules with const constructor,
/// strong type safety, and no dynamic types.
@immutable
class Song {
  /// Unique system media ID for the audio file.
  final int id;

  /// Title of the song.
  final String title;

  /// Artist or performer name.
  final String artist;

  /// Album title (optional).
  final String? album;

  /// Album ID used for querying album artwork thumbnail.
  final int? albumId;

  /// Total duration of the audio in milliseconds.
  final int durationMs;

  /// Absolute file path or content URI on device storage.
  final String dataUri;

  /// File size in bytes.
  final int? sizeBytes;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.albumId,
    required this.durationMs,
    required this.dataUri,
    this.sizeBytes,
  });

  /// Formatted duration string in "mm:ss" (or "h:mm:ss" if 60+ minutes).
  String get formattedDuration {
    final totalSeconds = (durationMs / 1000).round();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final secondsStr = seconds.toString().padLeft(2, '0');
    final minutesStr = minutes.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$minutesStr:$secondsStr';
    }
    return '$minutesStr:$secondsStr';
  }

  /// Creates a copy of this song with specified fields replaced.
  Song copyWith({
    int? id,
    String? title,
    String? artist,
    String? album,
    int? albumId,
    int? durationMs,
    String? dataUri,
    int? sizeBytes,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumId: albumId ?? this.albumId,
      durationMs: durationMs ?? this.durationMs,
      dataUri: dataUri ?? this.dataUri,
      sizeBytes: sizeBytes ?? this.sizeBytes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Song(id: $id, title: "$title", artist: "$artist")';
}
