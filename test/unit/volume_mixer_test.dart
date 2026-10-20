import 'package:flutter_test/flutter_test.dart';
import 'package:dozetone/core/constants/audio_constants.dart';
import 'package:dozetone/core/utils/volume_mixer.dart';

void main() {
  group('VolumeMixer unit tests', () {
    test('defaults give 1.0', () {
      final mixer = VolumeMixer();
      expect(mixer.timerFactor, 1.0);
      expect(mixer.duckFactor, 1.0);
      expect(mixer.effective, 1.0);
    });

    test('ducked alone gives 0.5', () {
      final mixer = VolumeMixer();
      mixer.setDucked(true);

      expect(mixer.timerFactor, 1.0);
      expect(mixer.duckFactor, AudioConstants.duckVolumeFactor);
      expect(mixer.effective, 0.5);
    });

    test('timer 0.4 with duck gives 0.2', () {
      final mixer = VolumeMixer();
      mixer.setTimerFactor(0.4);
      mixer.setDucked(true);

      expect(mixer.timerFactor, 0.4);
      expect(mixer.duckFactor, 0.5);
      expect(mixer.effective, closeTo(0.2, 1e-6));
    });

    test('duck ends while timer is 0.4: result is 0.4, not 1.0', () {
      final mixer = VolumeMixer();
      mixer.setTimerFactor(0.4);
      mixer.setDucked(true);
      expect(mixer.effective, closeTo(0.2, 1e-6));

      // Duck ends while sleep timer is still fading at 0.4
      mixer.setDucked(false);
      expect(mixer.effective, closeTo(0.4, 1e-6));
      expect(mixer.effective, isNot(1.0));
    });

    test('values are clamped between 0.0 and 1.0', () {
      final mixer = VolumeMixer();

      // Negative values clamped to 0.0
      mixer.setTimerFactor(-0.5);
      expect(mixer.effective, 0.0);

      // Values exceeding 1.0 clamped to 1.0
      mixer.setTimerFactor(1.5);
      mixer.setDucked(false);
      expect(mixer.effective, 1.0);
    });
  });
}
