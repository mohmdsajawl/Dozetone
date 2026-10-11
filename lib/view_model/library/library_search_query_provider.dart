import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider holding the current library search query entered by the user.
final libraryQueryProvider = StateProvider<String>((ref) {
  return '';
});
