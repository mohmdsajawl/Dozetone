import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dozetone/core/constants/pref_keys.dart';
import 'package:dozetone/data/repositories/song_repository.dart';
import 'package:dozetone/data/services/media_library_service.dart';
import 'package:dozetone/data/services/permission_service.dart';
import 'package:dozetone/model/song.dart';
import 'package:dozetone/view_model/library/library_state.dart';
import 'package:dozetone/view_model/library/library_view_model.dart';
import 'package:dozetone/view_model/settings/settings_view_model.dart';
import 'package:permission_handler/permission_handler.dart';

class FakeSongRepository implements SongRepository {
  List<Song> songs = <Song>[];
  int fetchCallCount = 0;

  @override
  Future<List<Song>> fetchSongs() async {
    fetchCallCount++;
    return songs;
  }

  @override
  Future<bool> deleteSong(Song song) async => true;

  @override
  Future<bool> renameSong(Song song, String newTitle) async => true;
}

class FakePermissionService implements PermissionService {
  @override
  Future<bool> isAudioPermissionGranted() async => true;

  @override
  Future<PermissionStatus> requestAudioPermission() async =>
      PermissionStatus.granted;

  @override
  Future<bool> isPermanentlyDenied() async => false;

  @override
  Future<bool> openSettings() async => true;

  @override
  Future<bool> ensureNotificationPermission() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MediaLibraryService.isExcludedAudio', () {
    test('identifies WhatsApp audio folder paths as excluded', () {
      expect(
        MediaLibraryService.isExcludedAudio(
          '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Audio/audio1.mp3',
        ),
        isTrue,
      );

      expect(
        MediaLibraryService.isExcludedAudio(
          '/storage/emulated/0/WhatsApp/Media/WhatsApp Audio/Sent/sample.mp3',
        ),
        isTrue,
      );

      expect(
        MediaLibraryService.isExcludedAudio(
          'C:\\Users\\User\\com.whatsapp\\Media\\WhatsApp Audio\\note.mp3',
        ),
        isTrue,
      );
    });

    test('identifies WhatsApp Voice Notes folder paths as excluded', () {
      expect(
        MediaLibraryService.isExcludedAudio(
          '/storage/emulated/0/WhatsApp/Media/WhatsApp Voice Notes/202305/voice.opus',
        ),
        isTrue,
      );

      expect(
        MediaLibraryService.isExcludedAudio(
          '/storage/emulated/0/Voice Notes/recording_01.m4a',
        ),
        isTrue,
      );
    });

    test('identifies Telegram and Call Recording paths as excluded', () {
      expect(
        MediaLibraryService.isExcludedAudio(
          '/storage/emulated/0/Telegram/Telegram Audio/clip.m4a',
        ),
        isTrue,
      );

      expect(
        MediaLibraryService.isExcludedAudio(
          '/storage/emulated/0/Recordings/CallRecordings/call_2023.mp3',
        ),
        isTrue,
      );

      expect(
        MediaLibraryService.isExcludedAudio(
          '/storage/emulated/0/SoundRecorder/rec.aac',
        ),
        isTrue,
      );
    });

    test('identifies WhatsApp file naming patterns (AUD-WA, PTT-WA) as excluded', () {
      expect(
        MediaLibraryService.isExcludedAudio(
          '/storage/emulated/0/Download/AUD-20230510-WA0001.mp3',
        ),
        isTrue,
      );

      expect(
        MediaLibraryService.isExcludedAudio(
          '/storage/emulated/0/Download/PTT-20230510-WA0002.opus',
        ),
        isTrue,
      );
    });

    test('does NOT exclude normal user music tracks', () {
      expect(
        MediaLibraryService.isExcludedAudio(
          '/storage/emulated/0/Music/Ed Sheeran - Shape of You.mp3',
        ),
        isFalse,
      );

      expect(
        MediaLibraryService.isExcludedAudio(
          '/storage/emulated/0/Download/Coldplay - Yellow.flac',
        ),
        isFalse,
      );

      expect(
        MediaLibraryService.isExcludedAudio(
          '/storage/emulated/0/Music/Album/01_Track.wav',
        ),
        isFalse,
      );

      expect(
        MediaLibraryService.isExcludedAudio(''),
        isFalse,
      );
    });
  });

  group('SettingsViewModel & Filter Rescan Integration', () {
    late FakeSongRepository fakeRepo;
    late FakePermissionService fakePerm;
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({
        PrefKeys.excludeWhatsappAudio: true,
        PrefKeys.shakeToExtend: true,
        PrefKeys.slowVolumeDecline: true,
        PrefKeys.fadeSeconds: 30,
      });

      fakeRepo = FakeSongRepository();
      fakePerm = FakePermissionService();

      container = ProviderContainer(
        overrides: [
          songRepositoryProvider.overrideWithValue(fakeRepo),
          permissionServiceProvider.overrideWithValue(fakePerm),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('loads default settings with excludeWhatsapp true', () async {
      final viewModel = container.read(settingsViewModelProvider.notifier);
      await viewModel.loadSettings();

      final state = container.read(settingsViewModelProvider);
      expect(state.excludeWhatsapp, isTrue);
      expect(state.shakeToExtend, isTrue);
      expect(state.slowVolumeDecline, isTrue);
      expect(state.fadeSeconds, equals(30));
    });

    test('toggling excludeWhatsapp triggers library rescan', () async {
      fakeRepo.songs = [
        const Song(
          id: 1,
          title: 'Morning Sun',
          artist: 'Ambient Art',
          durationMs: 180000,
          dataUri: '/storage/emulated/0/Music/morning.mp3',
        ),
      ];

      // Initialize library
      final libraryVm = container.read(libraryViewModelProvider.notifier);
      await libraryVm.scanSongs();
      expect(container.read(libraryViewModelProvider), isA<LibraryLoaded>());
      final initialFetchCount = fakeRepo.fetchCallCount;

      // Toggle excludeWhatsapp to false
      final settingsVm = container.read(settingsViewModelProvider.notifier);
      await settingsVm.toggleExcludeWhatsapp(false);

      final state = container.read(settingsViewModelProvider);
      expect(state.excludeWhatsapp, isFalse);

      // Verify SharedPreferences updated
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(PrefKeys.excludeWhatsappAudio), isFalse);

      // Verify library rescan was triggered
      expect(fakeRepo.fetchCallCount, greaterThan(initialFetchCount));
    });
  });
}
