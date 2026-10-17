import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State notifier managing selected song IDs for multi-select batch operations.
class MultiSelectNotifier extends StateNotifier<Set<int>> {
  MultiSelectNotifier() : super(<int>{});

  /// Whether multi-select mode is currently active.
  bool get isActive => state.isNotEmpty;

  /// Toggles selection state of [songId].
  void toggle(int songId) {
    if (state.contains(songId)) {
      state = Set<int>.from(state)..remove(songId);
    } else {
      state = Set<int>.from(state)..add(songId);
    }
  }

  /// Explicitly adds [songId] to selection.
  void select(int songId) {
    if (!state.contains(songId)) {
      state = Set<int>.from(state)..add(songId);
    }
  }

  /// Selects all [songIds].
  void selectAll(Iterable<int> songIds) {
    state = Set<int>.from(songIds);
  }

  /// Clears selection and exits multi-select mode.
  void clear() {
    state = <int>{};
  }

  /// Checks if [songId] is selected.
  bool isSelected(int songId) => state.contains(songId);
}

/// Provider exposing selected song IDs set for batch operations.
final multiSelectProvider =
    StateNotifierProvider<MultiSelectNotifier, Set<int>>((ref) {
  return MultiSelectNotifier();
});
