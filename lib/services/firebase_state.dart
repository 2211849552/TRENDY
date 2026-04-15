import 'package:flutter/foundation.dart';

class FirebaseState {
  static final FirebaseState _instance = FirebaseState._();
  factory FirebaseState() => _instance;
  FirebaseState._();

  final ValueNotifier<bool> ready = ValueNotifier<bool>(false);
  final ValueNotifier<String?> initError = ValueNotifier<String?>(null);
}

