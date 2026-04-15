import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'firebase_state.dart';

class FirebaseBootstrap {
  const FirebaseBootstrap();

  bool _isPlaceholderOptions(FirebaseOptions o) {
    // `flutterfire configure` will replace these.
    bool bad(String v) => v.trim().isEmpty || v.trim().toUpperCase() == 'CHANGE_ME';
    if (bad(o.apiKey)) return true;
    if (bad(o.appId)) return true;
    if (bad(o.projectId)) return true;
    if (bad(o.messagingSenderId)) return true;
    if (kIsWeb && bad(o.authDomain ?? '')) return true;
    return false;
  }

  /// Initializes Firebase if configured and signs in anonymously.
  ///
  /// If Firebase isn't configured yet (missing google-services files),
  /// this will fail silently and the app can still run (chat will not work).
  Future<void> init() async {
    try {
      // Firebase web plugins can crash under some web runtimes (e.g. WASM) if
      // the project isn't fully configured. Keep the app usable by disabling
      // Firebase on web until configured.
      if (kIsWeb) {
        FirebaseState().ready.value = false;
        FirebaseState().initError.value =
            'Firebase is disabled on web until configured. Run the app on Android/iOS, or configure Firebase then run with --no-wasm.';
        return;
      }

      final options = DefaultFirebaseOptions.currentPlatform;
      if (_isPlaceholderOptions(options)) {
        FirebaseState().ready.value = false;
        FirebaseState().initError.value =
            'Firebase options are placeholders. Run flutterfire configure.';
        return;
      }
      await Firebase.initializeApp(
        options: options,
      );
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }
      FirebaseState().ready.value = true;
    } catch (e) {
      FirebaseState().ready.value = false;
      FirebaseState().initError.value = e.toString();
      debugPrint('Firebase init skipped/failed: $e');
    }
  }
}

