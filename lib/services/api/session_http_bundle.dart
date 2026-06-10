import 'package:http/http.dart' as http;

/// حزمة عميل HTTP مع مورد أصلي اختياري (مثل HttpClient على الموبايل).
class SessionHttpBundle {
  const SessionHttpBundle(this.client, {this.nativeHandle});

  final http.Client client;
  final Object? nativeHandle;

  void close() {
    client.close();
  }
}
