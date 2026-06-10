import 'package:http/browser_client.dart';

import 'session_http_bundle.dart';

SessionHttpBundle createSessionHttpBundle() {
  final client = BrowserClient()..withCredentials = true;
  return SessionHttpBundle(client);
}

void closeNativeSessionHandle(Object? nativeHandle) {}
