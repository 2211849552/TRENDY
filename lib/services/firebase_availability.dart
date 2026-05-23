import 'package:flutter/foundation.dart';

import 'firebase_state.dart';

/// Firebase معطّل على الويب حتى يُهيّأ المشروع — لتجنب أخطاء JavaScriptObject.
bool get isFirebaseChatAvailable {
  if (kIsWeb) return false;
  return FirebaseState().ready.value;
}
