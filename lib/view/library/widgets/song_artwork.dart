import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../view_model/library/song_artwork_provider.dart';

/// In-memory cache for loaded artwork bitmaps.
/// Holds up to 300 thumbnail byte arrays to provide 60fps scrolling.
class SongArtworkCache {
  static final Map<int, Uint8List?> _cache = <int, Uint8List?>{};

  static bool contains(int songId) => _cache.containsKey(songId);
  static Uint8List? get(int songId) => _cache[songId];
  static void put(int songId, Uint8List? bytes) {
    if (_cache.length > 300) {
      _cache.remove(_cache.keys.first);
    }
    _cache[songId] = bytes;
  }
  static void clear() => _cache.clear();
}

/// Displays album artwork for a song with cached loading and vibrant gradient fallback.
class SongArtwork extends ConsumerStatefulWidget {
  final int songId;
  final int? albumId;
  final String? dataUri;
  final double size;
  final BorderRadius borderRadius;

  const SongArtwork({
    super.key,
    required this.songId,
    this.albumId,
    this.dataUri,
    this.size = AppDimensions.listArtSize,
    this.borderRadius = AppDimensions.borderRadiusArtworkSmall,
  });

  @override
  ConsumerState<SongArtwork> createState() => _SongArtworkState();
}

class _SongArtworkState extends ConsumerState<SongArtwork> {
  Uint8List? _bytes;
  bool _loaded = false;

  static List<List<Color>> get _placeholderGradients => AppColors.artworkGradients;

  @override
  void initState() {
    super.initState();
    _loadArtwork();
  }

  @override
  void didUpdateWidget(covariant SongArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.songId != widget.songId) {
      _loadArtwork();
    }
  }

  void _loadArtwork() {
    if (SongArtworkCache.contains(widget.songId)) {
      _bytes = SongArtworkCache.get(widget.songId);
      _loaded = true;
      return;
    }

    final queryArtwork = ref.read(songArtworkQueryProvider);
    queryArtwork(widget.songId, widget.albumId, dataUri: widget.dataUri)
        .then((bytes) {
      if (!mounted) return;
      SongArtworkCache.put(widget.songId, bytes);
      setState(() {
        _bytes = bytes;
        _loaded = true;
      });
    }).catchError((_) {
      if (!mounted) return;
      SongArtworkCache.put(widget.songId, null);
      setState(() {
        _bytes = null;
        _loaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: _loaded && _bytes != null && _bytes!.isNotEmpty
            ? Image.memory(
                _bytes!,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    final gradientColors =
        _placeholderGradients[widget.songId.abs() % _placeholderGradients.length];

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: widget.size * 0.48,
          color: AppColors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
