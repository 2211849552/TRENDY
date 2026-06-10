import 'package:http/http.dart' as http;

import 'session_http_bundle.dart';

SessionHttpBundle createSessionHttpBundle() {
  return SessionHttpBundle(http.Client());
}

void closeNativeSessionHandle(Object? nativeHandle) {}
