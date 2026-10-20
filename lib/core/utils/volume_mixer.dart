import '../constants/audio_constants.dart';

/// Pure volume mixer combining sleep timer factor and audio interruption ducking.
///
/// Prevents audio focus ducking (such as navigation or notification prompts)
/// from overwriting or resetting in-progress sleep timer volume curves.
class VolumeMixer {
  double timerFactor;
  double duckFactor;

  VolumeMixer({
    this.timerFactor = 1.0,
    this.duckFactor = 1.0,
  });

  /// Sets the volume factor requested by the sleep timer.
  void setTimerFactor(double factor) {
    timerFactor = factor;
  }

  /// Sets whether playback is currently ducked due to audio focus interruption.
  void setDucked(bool ducked) {
    duckFactor = ducked ? AudioConstants.duckVolumeFactor : 1.0;
  }

  /// Effective combined volume factor clamped between 0.0 and 1.0.
  double get effective => (timerFactor * duckFactor).clamp(0.0, 1.0);
}
