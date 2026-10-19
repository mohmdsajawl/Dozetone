import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../model/song.dart';
import '../../../view_model/player/player_view_model.dart';
import '../../library/widgets/song_artwork.dart';
import '../../widgets/music_wave_bars.dart';

/// Modal bottom sheet displaying the complete playback queue.
///
/// Features:
/// - Displays full queue with no tracks hidden or disappearing.
/// - Highlighted "Now Playing" card with live equalizer and play/pause controls.
/// - Long-press & drag from anywhere on any track to reorder, or drag handle on the right.
/// - Single-tap on any track immediately plays it without hiding previous tracks.
/// - Remove button on each track to delete it from the queue.
/// - Fully synced counter badge matching visible tracks.
/// - Consistent design adhering to Dozetone theme and bottom sheet conventions.
class PlaybackQueueModal extends ConsumerStatefulWidget {
  const PlaybackQueueModal({super.key});

  /// Displays the playback queue modal bottom sheet.
  static Future<void> show({required BuildContext context}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PlaybackQueueModal(),
    );
  }

  @override
  ConsumerState<PlaybackQueueModal> createState() => _PlaybackQueueModalState();
}

class _PlaybackQueueModalState extends ConsumerState<PlaybackQueueModal> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final playerState = ref.read(playerViewModelProvider);
      final currentIndex = playerState.currentIndex;
      // Scroll active track into view if positioned down the list
      if (currentIndex > 2 && _scrollController.hasClients) {
        final targetOffset = (currentIndex - 1) * 72.0;
        _scrollController.animateTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showFeedback(String message, IconData icon) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: <Widget>[
              Icon(icon, color: AppColors.accent, size: 20.0),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerViewModelProvider);
    final viewModel = ref.read(playerViewModelProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    final queue = playerState.queue;
    final currentIndex = playerState.currentIndex;
    final hasUpcoming = currentIndex >= 0 && currentIndex + 1 < queue.length;
    final sheetHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.borderRadiusBottomSheet,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black54,
            blurRadius: 30.0,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 1. Standard drag handle consistent with app modals
            Center(
              child: Container(
                margin: const EdgeInsets.only(
                  top: AppDimensions.space12,
                  bottom: AppDimensions.space8,
                ),
                width: 36.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),

            // 2. Header Row
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space8,
              ),
              child: Row(
                children: <Widget>[
                  Text(
                    l10n.queueTitle,
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 20.0),
                  ),
                  const SizedBox(width: AppDimensions.space12),

                  // Synchronized track count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space8,
                      vertical: AppDimensions.space2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.softAccent(0.15),
                      borderRadius: AppDimensions.borderRadiusPill,
                    ),
                    child: Text(
                      '${queue.length}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Clear Up Next action
                  if (hasUpcoming)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space12,
                          vertical: AppDimensions.space6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        viewModel.clearUpNext();
                        _showFeedback(
                          'Cleared upcoming tracks',
                          Icons.clear_all_rounded,
                        );
                      },
                      icon: const Icon(
                        Icons.clear_all_rounded,
                        size: 18.0,
                        color: AppColors.accent,
                      ),
                      label: Text(
                        l10n.clearQueue,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  const SizedBox(width: AppDimensions.space8),

                  // Close button
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22.0),
                    color: AppColors.textSecondary,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(color: AppColors.outline, height: 1.0),

            // 3. Queue List Body
            if (queue.isEmpty)
              Expanded(
                child: _buildEmptyQueue(
                  l10n.emptyQueue,
                  l10n.emptyQueuePrompt,
                ),
              )
            else
              Expanded(
                child: ReorderableListView.builder(
                  scrollController: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: queue.length,
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.space16,
                    AppDimensions.space12,
                    AppDimensions.space16,
                    AppDimensions.space24,
                  ),
                  proxyDecorator: (child, index, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, childWidget) {
                        final animValue =
                            Curves.easeInOut.transform(animation.value);
                        final elevation = lerpDouble(0, 10, animValue)!;
                        return Material(
                          elevation: elevation,
                          color: AppColors.surface,
                          shadowColor: Colors.black.withValues(alpha: 0.7),
                          borderRadius: AppDimensions.borderRadiusCard,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: AppDimensions.borderRadiusCard,
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.7),
                                width: 1.5,
                              ),
                            ),
                            child: childWidget,
                          ),
                        );
                      },
                      child: child,
                    );
                  },
                  // ignore: deprecated_member_use
                  onReorder: (oldIndex, newIndex) {
                    viewModel.reorderQueue(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final song = queue[index];
                    final isCurrentTrack = index == currentIndex;

                    return _buildQueueCard(
                      key: ValueKey('queue_item_${song.id}_$index'),
                      song: song,
                      index: index,
                      isCurrentTrack: isCurrentTrack,
                      isPlaying: playerState.isPlaying,
                      onTap: () async {
                        if (isCurrentTrack) {
                          viewModel.togglePlayPause();
                        } else {
                          await viewModel.skipToQueueIndex(index);
                        }
                      },
                      onRemove: () async {
                        await viewModel.removeFromQueue(index);
                        _showFeedback(
                          'Removed from queue',
                          Icons.remove_circle_outline_rounded,
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds a queue item card that supports:
  /// - Tap anywhere on card to play / toggle.
  /// - Long-press anywhere on card to drag-and-drop reorder.
  /// - Immediate drag handle on right for quick reordering without hold delay.
  /// - Remove button to delete track from queue.
  /// - Distinct visual highlight when the track is currently playing.
  Widget _buildQueueCard({
    required Key key,
    required Song song,
    required int index,
    required bool isCurrentTrack,
    required bool isPlaying,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    // ReorderableDelayedDragStartListener enables long-press dragging from anywhere on the card
    return ReorderableDelayedDragStartListener(
      key: key,
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.space8),
        decoration: BoxDecoration(
          color: isCurrentTrack
              ? AppColors.softAccent(0.12)
              : AppColors.background.withValues(alpha: 0.6),
          borderRadius: AppDimensions.borderRadiusCard,
          border: Border.all(
            color: isCurrentTrack
                ? AppColors.accent.withValues(alpha: 0.55)
                : AppColors.outline.withValues(alpha: 0.5),
            width: isCurrentTrack ? 1.5 : 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppDimensions.borderRadiusCard,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space12,
                vertical: AppDimensions.space8,
              ),
              child: Row(
                children: <Widget>[
                  // Artwork with live wave bars when currently playing
                  MusicArtworkOverlay(
                    isPlaying: isCurrentTrack && isPlaying,
                    size: 46.0,
                    borderRadius: AppDimensions.borderRadiusArtworkSmall,
                    child: SongArtwork(
                      songId: song.id,
                      albumId: song.albumId,
                      dataUri: song.dataUri,
                      size: 46.0,
                      borderRadius: AppDimensions.borderRadiusArtworkSmall,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space12),

                  // Song Title & Artist Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // "Now Playing" pill badge
                        if (isCurrentTrack) ...<Widget>[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Icon(
                                Icons.graphic_eq_rounded,
                                size: 13.0,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: AppDimensions.space4),
                              Text(
                                'NOW PLAYING',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.accent,
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.space2),
                        ],

                        Text(
                          song.title,
                          style: isCurrentTrack
                              ? AppTextStyles.songTitleActive.copyWith(fontSize: 14.0)
                              : AppTextStyles.songTitle.copyWith(fontSize: 14.0),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppDimensions.space2),
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                song.artist,
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 12.0,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '  •  ${song.formattedDuration}',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 11.0,
                                color: AppColors.textSecondary.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // If current track: inline play/pause toggle
                  if (isCurrentTrack)
                    IconButton(
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded,
                        color: AppColors.accent,
                        size: 28.0,
                      ),
                      tooltip: isPlaying ? 'Pause' : 'Play',
                      onPressed: onTap,
                    ),

                  // Remove from queue button
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18.0,
                      color: AppColors.textSecondary,
                    ),
                    tooltip: 'Remove from queue',
                    visualDensity: VisualDensity.compact,
                    onPressed: onRemove,
                  ),

                  // Dedicated Drag Handle for immediate zero-delay drag
                  ReorderableDragStartListener(
                    index: index,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space8,
                        vertical: AppDimensions.space8,
                      ),
                      color: Colors.transparent,
                      child: const Icon(
                        Icons.drag_handle_rounded,
                        color: AppColors.textSecondary,
                        size: 20.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyQueue(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.queue_music_rounded,
              size: 56.0,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppDimensions.space16),
            Text(
              title,
              style: AppTextStyles.screenTitle.copyWith(fontSize: 18.0),
            ),
            const SizedBox(height: AppDimensions.space8),
            Text(
              subtitle,
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
