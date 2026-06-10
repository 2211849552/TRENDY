import 'dart:io';

import 'package:http/io_client.dart';

import 'session_http_bundle.dart';

SessionHttpBundle createSessionHttpBundle() {
  final httpClient = HttpClient();
  return SessionHttpBundle(
    IOClient(httpClient),
    nativeHandle: httpClient,
  );
}

void closeNativeSessionHandle(Object? nativeHandle) {
  if (nativeHandle is HttpClient) {
    nativeHandle.close(force: true);
  }
}
