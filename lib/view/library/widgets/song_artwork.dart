import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/services/media_library_service.dart';

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

  static const List<List<Color>> _placeholderGradients = [
    [Color(0xFF0E7490), Color(0xFF0F172A)], // Cyan to Dark Navy
    [Color(0xFF4338CA), Color(0xFF0F172A)], // Indigo to Dark Navy
    [Color(0xFF7C3AED), Color(0xFF18181B)], // Purple to Dark Void
    [Color(0xFF059669), Color(0xFF0F172A)], // Emerald to Dark Navy
    [Color(0xFFD97706), Color(0xFF1C1917)], // Amber to Charcoal
    [Color(0xFFE11D48), Color(0xFF0F172A)], // Rose to Dark Navy
  ];

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

    final mediaService = ref.read(mediaLibraryServiceProvider);
    mediaService
        .queryArtwork(widget.songId, widget.albumId, dataUri: widget.dataUri)
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
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
