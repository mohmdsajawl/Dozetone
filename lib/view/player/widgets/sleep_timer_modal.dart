import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../model/sleep_timer_state.dart';
import '../../../../model/song.dart';
import '../../../view_model/player/player_view_model.dart';
import '../../../view_model/sleep_timer/sleep_timer_view_model.dart';
import '../../library/widgets/song_artwork.dart';
import 'sleep_tracks_picker_modal.dart';

/// Modal bottom sheet presenting sleep timer options (Duration & Tracks),
/// custom time slider, track-based song picker, and dynamic in-flight timer editing.
class SleepTimerModal extends ConsumerStatefulWidget {
  const SleepTimerModal({super.key});

  /// Displays the Sleep Timer modal bottom sheet.
  static Future<void> show({required BuildContext context}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => const SleepTimerModal(),
    );
  }

  @override
  ConsumerState<SleepTimerModal> createState() => _SleepTimerModalState();
}

class _SleepTimerModalState extends ConsumerState<SleepTimerModal>
    with SingleTickerProviderStateMixin {
  late final TabController _modeTabController;

  // Inactive mode local controls
  int _customMinutes = 25;
  int _tracksCount = 3;

  // Active mode local controls
  bool _isSliderExpanded = false;
  double? _activeSliderMinutes;

  @override
  void initState() {
    super.initState();
    _modeTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _modeTabController.dispose();
    super.dispose();
  }

  void _showTimerSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: <Widget>[
              const Icon(
                Icons.bedtime_rounded,
                color: AppColors.accent,
                size: 20.0,
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  void _startPresetTimer({
    required Duration duration,
    required String label,
  }) {
    Navigator.of(context).pop();
    ref.read(sleepTimerProvider.notifier).startTimer(duration, choiceLabel: label);

    final l10n = AppLocalizations.of(context)!;
    _showTimerSnackbar(context, l10n.timerSetSnackbar(label));
  }

  void _startEndOfSongTimer({required String label}) {
    Navigator.of(context).pop();
    ref.read(sleepTimerProvider.notifier).startEndOfSongTimer(choiceLabel: label);

    final l10n = AppLocalizations.of(context)!;
    _showTimerSnackbar(context, l10n.timerSetSnackbar(label));
  }

  void _startTracksCountTimer(int count) {
    Navigator.of(context).pop();
    ref.read(sleepTimerProvider.notifier).startTracksTimer(
          trackCount: count,
          choiceLabel: '$count tracks',
        );

    final label = '$count ${count == 1 ? "track" : "tracks"}';
    _showTimerSnackbar(context, 'Sleep timer set for $label');
  }

  Future<void> _handleSpecificTracksSelection(List<Song> selectedTracks) async {
    if (selectedTracks.isEmpty) return;

    final playerViewModel = ref.read(playerViewModelProvider.notifier);
    final sleepTimerViewModel = ref.read(sleepTimerProvider.notifier);

    // Immediately start the sleep timer with selected tracks
    await sleepTimerViewModel.startTracksTimer(
      trackCount: selectedTracks.length,
      specificTracks: selectedTracks,
      choiceLabel: '${selectedTracks.length} tracks',
    );

    // Immediately start playing the selected tracks starting from the first chosen song
    await playerViewModel.playSong(selectedTracks.first, selectedTracks);

    if (mounted) {
      Navigator.of(context).pop();
      final label =
          '${selectedTracks.length} ${selectedTracks.length == 1 ? "track" : "tracks"}';
      _showTimerSnackbar(context, 'Sleep timer set for $label');
    }
  }

  Future<void> _openSongPicker() async {
    final picked = await SleepTracksPickerModal.show(context: context);
    if (picked != null && picked.isNotEmpty && mounted) {
      await _handleSpecificTracksSelection(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timerState = ref.watch(sleepTimerProvider);
    final viewModel = ref.read(sleepTimerProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.borderRadiusBottomSheet,
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.6),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16,
            vertical: AppDimensions.space16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Drag Handle
              Center(
                child: Container(
                  width: 36.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space16),

              // Header: Moon icon + Title
              Row(
                children: <Widget>[
                  Container(
                    width: 38.0,
                    height: 38.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withValues(alpha: 0.15),
                    ),
                    child: const Icon(
                      Icons.bedtime_rounded,
                      color: AppColors.accent,
                      size: 20.0,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.sleepTimer,
                        style: AppTextStyles.screenTitle.copyWith(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        timerState.isActive
                            ? l10n.timerRunningTouchToAdjust
                            : l10n.setByDurationOrTracks,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (timerState.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space8,
                        vertical: 3.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.2),
                        borderRadius: AppDimensions.borderRadiusPill,
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            width: 6.0,
                            height: 6.0,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            l10n.activeStatus,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 11.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.space16),

              // Body: Active Timer View vs Inactive Setup View
              if (timerState.isActive)
                _buildActiveTimerView(l10n, timerState, viewModel)
              else
                _buildInactiveTimerSetup(l10n, timerState),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ACTIVE TIMER VIEW (DYNAMIC IN-FLIGHT CONTROLS & LIVE PROGRESS)
  // ---------------------------------------------------------------------------

  Widget _buildActiveTimerView(
    AppLocalizations l10n,
    SleepTimerState timerState,
    SleepTimerViewModel viewModel,
  ) {
    final isTrack = timerState.isTrackBased;
    final playerState = ref.watch(playerViewModelProvider);
    final currentSong = playerState.currentSong;

    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          // Hero Glowing Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.space16,
              horizontal: AppDimensions.space16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  AppColors.accent.withValues(alpha: 0.12),
                  AppColors.surface.withValues(alpha: 0.8),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              children: <Widget>[
                Text(
                  isTrack
                      ? l10n.tracksRemainingBadge(timerState.remainingTracks)
                      : timerState.formattedRemaining,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: isTrack ? 32.0 : 44.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppDimensions.space6),

                // Subtitle / Fade indicator badge
                if (timerState.isFadingOut)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space12,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.25),
                      borderRadius: AppDimensions.borderRadiusPill,
                      border: Border.all(
                        color: AppColors.accent,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.graphic_eq_rounded,
                          size: 15.0,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: AppDimensions.space6),
                        Text(
                          l10n.fadingOut,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    isTrack
                        ? (timerState.remainingTracks == 1
                            ? l10n.fadingOutOfTrack
                            : l10n.playbackPausesAfterTracks(
                                timerState.remainingTracks,
                              ))
                        : l10n.musicWillGentlyFadeOut,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space12),

          // LIVE TRACK PROGRESS CARD (Shows live ticking progress for current song in track mode)
          if (isTrack && currentSong != null) ...<Widget>[
            Container(
              padding: const EdgeInsets.all(AppDimensions.space12),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: SizedBox(
                          width: 38.0,
                          height: 38.0,
                          child: SongArtwork(
                            songId: currentSong.id,
                            albumId: currentSong.albumId,
                            dataUri: currentSong.dataUri,
                            size: 38.0,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              currentSong.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.0,
                              ),
                            ),
                            Text(
                              currentSong.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (timerState.totalTracks > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 3.0,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: AppDimensions.borderRadiusPill,
                          ),
                          child: Text(
                            'Track ${(timerState.totalTracks - timerState.remainingTracks + 1).clamp(1, timerState.totalTracks)} of ${timerState.totalTracks}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 11.0,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: LinearProgressIndicator(
                      value: playerState.duration.inMilliseconds > 0
                          ? (playerState.position.inMilliseconds /
                                  playerState.duration.inMilliseconds)
                              .clamp(0.0, 1.0)
                          : 0.0,
                      backgroundColor:
                          AppColors.outline.withValues(alpha: 0.3),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.accent),
                      minHeight: 4.0,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        playerState.position.inMinutes > 0
                            ? '${playerState.position.inMinutes}:${(playerState.position.inSeconds % 60).toString().padLeft(2, '0')}'
                            : '0:${(playerState.position.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10.5,
                        ),
                      ),
                      Text(
                        playerState.duration > playerState.position
                            ? '-${(playerState.duration - playerState.position).inMinutes}:${((playerState.duration - playerState.position).inSeconds % 60).toString().padLeft(2, '0')}'
                            : '0:00',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space12),
          ],

          // IN-FLIGHT DYNAMIC EDITORS
          if (!isTrack) ...<Widget>[
            // Time-Based Quick Steppers: [-] 5m, [-] 1m, [+] 1m, [+] 5m (NO duplicate signs!)
            Row(
              children: <Widget>[
                _buildStepperButton(
                  label: '5m',
                  icon: Icons.remove_rounded,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    viewModel.adjustTime(const Duration(minutes: -5));
                  },
                ),
                const SizedBox(width: AppDimensions.space8),
                _buildStepperButton(
                  label: '1m',
                  icon: Icons.remove_rounded,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    viewModel.adjustTime(const Duration(minutes: -1));
                  },
                ),
                const SizedBox(width: AppDimensions.space8),
                _buildStepperButton(
                  label: '1m',
                  icon: Icons.add_rounded,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    viewModel.adjustTime(const Duration(minutes: 1));
                  },
                ),
                const SizedBox(width: AppDimensions.space8),
                _buildStepperButton(
                  label: '5m',
                  icon: Icons.add_rounded,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    viewModel.adjustTime(const Duration(minutes: 5));
                  },
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space12),

            // Toggle for fine-tuning slider
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isSliderExpanded = !_isSliderExpanded;
                    if (_isSliderExpanded) {
                      _activeSliderMinutes =
                          timerState.remainingDuration.inMinutes.toDouble();
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space12,
                    vertical: AppDimensions.space8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: AppColors.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        _isSliderExpanded
                            ? Icons.expand_less_rounded
                            : Icons.tune_rounded,
                        size: 16.0,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: AppDimensions.space6),
                      Text(
                        _isSliderExpanded
                            ? l10n.closeSlider
                            : l10n.adjustWithSlider,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_isSliderExpanded) ...<Widget>[
              const SizedBox(height: AppDimensions.space12),
              Container(
                padding: const EdgeInsets.all(AppDimensions.space12),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(
                    color: AppColors.outline.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'Drag to set duration:',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${(_activeSliderMinutes ?? timerState.remainingDuration.inMinutes).round()} min',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.accent,
                        inactiveTrackColor: AppColors.outline,
                        thumbColor: AppColors.textPrimary,
                        overlayColor: AppColors.accent.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: (_activeSliderMinutes ??
                                timerState.remainingDuration.inMinutes.toDouble())
                            .clamp(1.0, 180.0),
                        min: 1.0,
                        max: 180.0,
                        divisions: 179,
                        onChanged: (val) {
                          setState(() => _activeSliderMinutes = val);
                        },
                        onChangeEnd: (val) {
                          viewModel.setTime(Duration(minutes: val.round()));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...<Widget>[
            // Track-Based Steppers: [-] 1 Track, [+] 1 Track (NO duplicate signs!)
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      viewModel.removeTracks(1);
                    },
                    icon: const Icon(Icons.remove_rounded, size: 18.0),
                    label: const Text('1 Track'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(
                        color: AppColors.outline.withValues(alpha: 0.6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.space12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      viewModel.addTracks(1);
                    },
                    icon: const Icon(Icons.add_rounded, size: 18.0),
                    label: const Text('1 Track'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                      foregroundColor: AppColors.accent,
                      elevation: 0,
                      side: BorderSide(
                        color: AppColors.accent.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.space12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space12),

            // If specific tracks are selected: list with remove & add more
            if (timerState.selectedTracks.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.space12),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(
                    color: AppColors.outline.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'Queued Sleep Tracks (${timerState.selectedTracks.length})',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            final picked = await SleepTracksPickerModal.show(
                              context: context,
                              initialSelected: timerState.selectedTracks,
                            );
                            if (picked != null && mounted) {
                              // Enqueue any new songs
                              final playerVm =
                                  ref.read(playerViewModelProvider.notifier);
                              for (final song in picked) {
                                if (!timerState.selectedTracks
                                    .any((s) => s.id == song.id)) {
                                  playerVm.addToQueue(song);
                                }
                              }
                              await viewModel.updateSelectedTracks(picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(6.0),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 2.0,
                            ),
                            child: Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.add_rounded,
                                  size: 14.0,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 2.0),
                                Text(
                                  l10n.addMore,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 140.0),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: timerState.selectedTracks.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 4.0),
                        itemBuilder: (context, index) {
                          final song = timerState.selectedTracks[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.space8,
                              vertical: 4.0,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Row(
                              children: <Widget>[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6.0),
                                  child: SizedBox(
                                    width: 28.0,
                                    height: 28.0,
                                    child: SongArtwork(
                                      songId: song.id,
                                      albumId: song.albumId,
                                      dataUri: song.dataUri,
                                      size: 28.0,
                                      borderRadius: BorderRadius.circular(6.0),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.space8),
                                Expanded(
                                  child: Text(
                                    song.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 16.0,
                                    color: AppColors.textSecondary,
                                  ),
                                  onPressed: () {
                                    final updated = List<Song>.from(
                                      timerState.selectedTracks,
                                    )..removeAt(index);
                                    viewModel.updateSelectedTracks(updated);
                                  },
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: AppDimensions.space16),

          // Primary Actions: Quick Extend & Cancel
          Row(
            children: <Widget>[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    viewModel.add5Minutes();
                  },
                  icon: const Icon(Icons.add_rounded, size: 20.0),
                  label: Text(isTrack ? '1 Track' : l10n.add5Min),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.space12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    viewModel.cancelTimer();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close_rounded, size: 20.0),
                  label: Text(l10n.cancelTimer),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.space12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Shake to extend hint
          if (timerState.shakeToExtendEnabled) ...<Widget>[
            const SizedBox(height: AppDimensions.space12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space12,
                vertical: AppDimensions.space8,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.vibration_rounded,
                    size: 16.0,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: AppDimensions.space8),
                  Text(
                    l10n.shakeToExtendHint,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.space8),
        ],
      ),
    );
  }

  Widget _buildStepperButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: AppColors.outline.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 14.0, color: AppColors.accent),
                const SizedBox(width: 4.0),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INACTIVE TIMER SETUP VIEW (DURATION VS TRACKS TABS)
  // ---------------------------------------------------------------------------

  Widget _buildInactiveTimerSetup(
    AppLocalizations l10n,
    SleepTimerState timerState,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Mode Selector: Duration vs Tracks
        Container(
          height: 38.0,
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: AppColors.outline.withValues(alpha: 0.4),
            ),
          ),
          child: TabBar(
            controller: _modeTabController,
            indicator: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.5),
              ),
            ),
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13.0,
            ),
            unselectedLabelStyle: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w400,
              fontSize: 13.0,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: <Widget>[
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.schedule_rounded, size: 16.0),
                    const SizedBox(width: AppDimensions.space6),
                    Text(l10n.tabDuration),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.queue_music_rounded, size: 16.0),
                    const SizedBox(width: AppDimensions.space6),
                    Text(l10n.tabTracks),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.space16),

        // Tab Views (Constrained Height with smooth scroll)
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.52,
          ),
          child: TabBarView(
            controller: _modeTabController,
            children: <Widget>[
              _buildDurationPresetsTab(l10n, timerState),
              _buildTracksModeTab(l10n),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.space12),

        // Shake to Extend Toggle Setting
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16,
            vertical: AppDimensions.space8,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(
              color: AppColors.outline.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.vibration_rounded,
                size: 18.0,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.shakeToExtendTitle,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      l10n.shakeToExtendHint,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: timerState.shakeToExtendEnabled,
                activeThumbColor: AppColors.accent,
                onChanged: (val) {
                  ref.read(sleepTimerProvider.notifier).setShakeToExtend(val);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: DURATION PRESETS & CUSTOM SLIDER
  // ---------------------------------------------------------------------------

  Widget _buildDurationPresetsTab(
    AppLocalizations l10n,
    SleepTimerState timerState,
  ) {
    final presets = <({String label, Duration duration})>[
      (label: l10n.timerPreset5Min, duration: const Duration(minutes: 5)),
      (label: l10n.timerPreset10Min, duration: const Duration(minutes: 10)),
      (label: l10n.timerPreset15Min, duration: const Duration(minutes: 15)),
      (label: l10n.timerPreset30Min, duration: const Duration(minutes: 30)),
      (label: l10n.timerPreset45Min, duration: const Duration(minutes: 45)),
      (label: l10n.timerPreset60Min, duration: const Duration(minutes: 60)),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 2-Column Preset Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: presets.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8.0,
              crossAxisSpacing: 8.0,
              childAspectRatio: 2.8,
            ),
            itemBuilder: (context, index) {
              final preset = presets[index];
              final isLastUsed = timerState.lastUsedChoice == preset.label;
              final accentHighlight =
                  Color.lerp(AppColors.accent, AppColors.white, 0.25)!;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _startPresetTimer(
                      duration: preset.duration,
                      label: preset.label,
                    );
                  },
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space12,
                      vertical: AppDimensions.space8,
                    ),
                    decoration: BoxDecoration(
                      color: isLastUsed
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : AppColors.surface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: isLastUsed
                            ? AppColors.accent.withValues(alpha: 0.5)
                            : AppColors.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.schedule_rounded,
                          size: 16.0,
                          color: isLastUsed
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppDimensions.space8),
                        Expanded(
                          child: Text(
                            preset.label,
                            style: AppTextStyles.body.copyWith(
                              color: isLastUsed
                                  ? accentHighlight
                                  : AppColors.textPrimary,
                              fontWeight: isLastUsed
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 13.0,
                            ),
                          ),
                        ),
                        if (isLastUsed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.25),
                              borderRadius: AppDimensions.borderRadiusPill,
                            ),
                            child: Text(
                              l10n.lastBadge,
                              style: AppTextStyles.caption.copyWith(
                                color: accentHighlight,
                                fontSize: 10.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppDimensions.space12),

          // Custom Duration Slider Card
          Container(
            padding: const EdgeInsets.all(AppDimensions.space16),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(
                color: AppColors.outline.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.tune_rounded,
                          size: 16.0,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: AppDimensions.space8),
                        Text(
                          l10n.customDuration,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      l10n.customMinutesLabel(_customMinutes),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 16.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space6),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.accent,
                    inactiveTrackColor: AppColors.outline,
                    thumbColor: AppColors.textPrimary,
                    overlayColor: AppColors.accent.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: _customMinutes.toDouble(),
                    min: 1.0,
                    max: 180.0,
                    divisions: 179,
                    onChanged: (val) {
                      setState(() => _customMinutes = val.round());
                    },
                  ),
                ),
                Row(
                  children: <Widget>[
                    // Quick step pills
                    _buildQuickMinuteChip(-5),
                    const SizedBox(width: 6.0),
                    _buildQuickMinuteChip(5),
                    const SizedBox(width: 6.0),
                    _buildQuickMinuteChip(15),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        _startPresetTimer(
                          duration: Duration(minutes: _customMinutes),
                          label: l10n.customMinutesLabelFull(_customMinutes),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.onAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space16,
                          vertical: 8.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 0,
                      ),
                      child: Text(l10n.startTimerButton),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMinuteChip(int delta) {
    return InkWell(
      onTap: () {
        setState(() {
          _customMinutes = (_customMinutes + delta).clamp(1, 180);
        });
      },
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: AppColors.outline.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          delta > 0 ? '+$delta' : '$delta',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: TRACKS MODE (END OF TRACK, COUNT STEPPER, PICK SONGS)
  // ---------------------------------------------------------------------------

  Widget _buildTracksModeTab(AppLocalizations l10n) {
    final playerState = ref.watch(playerViewModelProvider);
    final currentSong = playerState.currentSong;

    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          // Option A: End of Current Track Card
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _startEndOfSongTimer(label: l10n.timerEndOfSong),
              borderRadius: BorderRadius.circular(14.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space16,
                  vertical: AppDimensions.space12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(
                    color: AppColors.outline.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 40.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent.withValues(alpha: 0.15),
                      ),
                      child: const Icon(
                        Icons.music_note_rounded,
                        color: AppColors.accent,
                        size: 20.0,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            l10n.timerEndOfSong,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.0,
                            ),
                          ),
                          Text(
                            currentSong != null
                                ? l10n.pausesWhenTrackFinishes(currentSong.title)
                                : l10n.pausesWhenCurrentFinishes,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14.0,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.space8),

          // Option B: Number of Tracks Stepper Card (Spacious, centered, no double-digit overflow!)
          Container(
            padding: const EdgeInsets.all(AppDimensions.space16),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(
                color: AppColors.outline.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.repeat_one_rounded,
                      size: 18.0,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: AppDimensions.space8),
                    Text(
                      l10n.trackCountTimer,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: AppDimensions.borderRadiusPill,
                      ),
                      child: Text(
                        l10n.countBased,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.accent,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space12),

                // Centered Stepper with plenty of breathing room
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      color: _tracksCount > 1
                          ? AppColors.accent
                          : AppColors.textSecondary.withValues(alpha: 0.4),
                      iconSize: 26.0,
                      onPressed: _tracksCount > 1
                          ? () => setState(() => _tracksCount--)
                          : null,
                    ),
                    const SizedBox(width: AppDimensions.space16),
                    Container(
                      constraints: const BoxConstraints(minWidth: 110.0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space16,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        l10n.tracksCount(_tracksCount),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 15.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space16),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      color: AppColors.accent,
                      iconSize: 26.0,
                      onPressed: () => setState(() => _tracksCount++),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _startTracksCountTimer(_tracksCount),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.onAccent,
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      elevation: 0,
                    ),
                    child: Text(l10n.startTracksSleepTimer(_tracksCount)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space8),

          // Option C: Pick Specific Songs from Queue / Library Card
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openSongPicker,
              borderRadius: BorderRadius.circular(14.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space16,
                  vertical: AppDimensions.space12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      AppColors.accent.withValues(alpha: 0.15),
                      AppColors.surface.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 40.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent.withValues(alpha: 0.2),
                      ),
                      child: const Icon(
                        Icons.playlist_add_check_rounded,
                        color: AppColors.accent,
                        size: 22.0,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            l10n.pickSpecificSongs,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Color.lerp(
                                AppColors.accent,
                                AppColors.white,
                                0.2,
                              ),
                              fontSize: 14.0,
                            ),
                          ),
                          Text(
                            l10n.selectExactSongsPrompt,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space8,
                        vertical: 5.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        l10n.selectArrow,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.onAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
