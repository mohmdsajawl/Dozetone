# Dozetone

<p align="center">
  <strong>The intelligent offline music player engineered for bedtime listening and restful sleep.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Platform-Android%20API%2026%2B-3DDC84?logo=android" alt="Android">
  <img src="https://img.shields.io/badge/Architecture-Clean%20MVVM-FF6F00" alt="Architecture">
  <img src="https://img.shields.io/badge/State%20Management-Riverpod-blueviolet" alt="Riverpod">
  <img src="https://img.shields.io/badge/Tests-153%20Passing-brightgreen" alt="Tests">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
</p>

---

## Overview

Most mobile music players are designed for active listening. They keep playing all night after you fall asleep, draining your device battery and disrupting deep sleep cycles with loud volume transitions.

**Dozetone** is an offline Android music player crafted specifically for bedtime routines. It blends high-fidelity local audio playback with intelligent sleep timer automation, subtle physical gestures, and gentle volume fading to transition your mind into natural, undisturbed sleep.

---

## Key Sleep Features

### 1. Gentle Volume Fade-Out
Audio never stops abruptly. As the timer approaches zero, playback volume glides smoothly downward across a configurable fade window (e.g., 30s to 2 minutes) so your subconscious mind is not startled awake by sudden silence.

### 2. Shake-to-Extend Timer
If you are still awake as the timer winds down, you do not need to turn on your screen, face blue light, or navigate menus. Simply give your device a gentle shake to seamlessly add 5, 10, or 15 minutes to your session.

### 3. Slow Volume Decline
Gradually reduces audio volume at a calibrated slope throughout the active timer duration. By slowly decreasing auditory stimulation over 30 or 60 minutes, Dozetone mirrors the natural deceleration of your brainwaves as you drift off.

### 4. Bedtime Auto-Timer
Define your habitual bedtime window (for example, 10:30 PM to 6:00 AM). When playback begins during these hours, Dozetone automatically activates your preferred sleep timer without requiring manual setup every night.

### 5. Lockscreen & Notification Quick Actions
A dedicated `+5 Min` quick-action button in the persistent Android media notification and lockscreen controls lets you extend sleep playback with a single tap without unlocking your phone.

---

## 100% Private & Fully Offline

- **Zero Tracking**: No analytics libraries, crash loggers, or telemetry SDKs.
- **Zero Internet Access**: Android release manifest contains zero internet permissions.
- **On-Device Storage**: All songs, metadata, album art, and playback states remain strictly on your local device.

---

## Architecture & Code Quality

Dozetone is engineered following strict **Clean MVVM (Model - View - ViewModel)** principles and unidirectional data flow powered by **Riverpod**:

```
lib/
├── core/                  # Design system, constants, themes, and shared utilities
│   ├── constants/         # App constants, layout dimensions, asset paths
│   ├── theme/             # Color tokens, typography, dark theme configuration
│   └── utils/             # Formatters, helper extensions, duration parsing
├── data/                  # Data layer: Models, data sources, and repositories
│   ├── models/            # Immutable data structures (Song, Playlist, SleepTimer)
│   ├── repositories/      # Repository contracts and concrete implementations
│   └── services/          # Low-level hardware, audio engine, sensors, and database
├── l10n/                  # ARB-based localization files and generated delegates
├── routes/                # Declarative GoRouter routing definitions
├── view/                  # Presentation layer: Screens, modals, and reusable widgets
│   ├── home/              # Main library view (songs, artists, albums, playlists)
│   ├── now_playing/       # Fullscreen player with scrubber and sleep indicators
│   ├── sleep_timer/       # Timer configuration modal, presets, and bedtime schedules
│   └── widgets/           # Atomic UI components, artwork loaders, and cards
└── view_model/            # Application state management (Riverpod StateNotifiers)
    ├── library/           # Audio query state, sorting, search, multi-select
    ├── player/            # Playback state, queue management, volume interpolation
    ├── playlist/          # Playlist CRUD and song assignment
    └── sleep_timer/       # Active timer countdown, shake detection, bedtime watcher
```

### Architectural Guarantees
- **Separation of Concerns**: Presentation widgets in `lib/view/` never communicate directly with data repositories or system services. They interact solely with ViewModels.
- **Testable State**: ViewModels have zero dependencies on `BuildContext` or Flutter widget trees, allowing pure unit testing of business logic.
- **Localization**: UI text is organized into ARB format ([lib/l10n/app_en.arb](lib/l10n/app_en.arb)) with type-safe generated accessors via `AppLocalizations`.

---

## Tech Stack & Dependencies

| Package | Purpose & Justification |
| :--- | :--- |
| **flutter_riverpod** | Robust, compile-safe state management and dependency injection without BuildContext reliance. |
| **go_router** | Declarative navigation supporting type-safe routes, deep links, and modal sheets. |
| **just_audio** | High-performance, gapless local audio playback engine with precise volume fading controls. |
| **audio_service** | Seamless Android background execution, lockscreen media controls, and notification integration. |
| **audio_session** | Manages system audio focus (handling incoming phone calls, GPS ducking, and headphone unplugging). |
| **sensors_plus** | Accelerometer hardware sensor integration for energy-efficient shake detection. |
| **shared_preferences** | Fast, local key-value persistence for bedtime schedules, volume curves, and user preferences. |
| **permission_handler** | Clean, reactive handling of runtime storage and Android 13+ notification permissions. |
| **flutter_svg** | High-fidelity vector rendering for custom sleep timer, moon, and playback icons. |

---

## Getting Started

### Prerequisites
- **Flutter SDK**: `^3.x`
- **Dart SDK**: `^3.x`
- **Android SDK**: Min API 26 (Android 8.0 Oreo) or higher

### Installation & Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/mohmdsajawl/Dozetone.git
   cd Dozetone
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate localization files**:
   ```bash
   flutter gen-l10n
   ```

4. **Run the application**:
   ```bash
   flutter run
   ```

---

## Quality Assurance & Testing

The project maintains 100% pass rates across static analysis and automated test suites:

- **Static Analysis**:
  ```bash
  flutter analyze lib test
  # Result: No issues found!
  ```

- **Automated Tests**:
  ```bash
  flutter test
  # Result: 153/153 tests passed (Unit, Widget, and Service tests)
  ```

- **Release Build Check**:
  ```bash
  flutter build apk --release
  ```

---

## Author

- **Muhammad Sajawal** - Developer and Maintainer

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for complete details.
