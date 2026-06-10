import 'package:flutter/material.dart';

import '../services/api/api_exception.dart';
import '../services/api/complaints_api.dart';
import 'auth_session.dart';
import 'complaint.dart';

class ComplaintsManager extends ChangeNotifier {
  static final ComplaintsManager _instance = ComplaintsManager._internal();
  factory ComplaintsManager() => _instance;
  ComplaintsManager._internal();

  final ComplaintsApi _api = ComplaintsApi();
  final List<Complaint> _complaints = [];
  bool _loading = false;
  String? _error;

  bool get isLoading => _loading;
  String? get error => _error;
  List<Complaint> get complaints => List.unmodifiable(_complaints);
  int get count => _complaints.length;

  /// GET /api/complaints/mine
  Future<void> syncFromApi() async {
    if (!AuthSession.instance.isAuthenticated) {
      _complaints.clear();
      _error = null;
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final list = await _api.fetchMyComplaints();
      _complaints
        ..clear()
        ..addAll(list);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// POST /api/complaints
  Future<bool> submitComplaint({
    required String typeKey,
    required String subject,
    required String details,
    required int orderId,
  }) async {
    if (!AuthSession.instance.isAuthenticated) {
      _error = 'يجب تسجيل الدخول لإرسال شكوى';
      notifyListeners();
      return false;
    }

    _error = null;
    try {
      final created = await _api.createComplaint(
        orderId: orderId,
        category: Complaint.categoryForTypeKey(typeKey),
        subject: subject,
        description: details,
      );
      _complaints.insert(0, created);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// POST /api/complaints/{id}/replies
  Future<bool> addReply({
    required String complaintId,
    required String message,
  }) async {
    _error = null;
    final index = _complaints.indexWhere((c) => c.id == complaintId);
    if (index < 0) return false;

    final complaint = _complaints[index];
    final apiId = complaint.apiId;
    if (apiId == null) return false;

    if (!AuthSession.instance.isAuthenticated) {
      _error = 'يجب تسجيل الدخول لإضافة رد';
      notifyListeners();
      return false;
    }

    try {
      await _api.addReply(complaintId: apiId, message: message);
      final refreshed = await _api.fetchComplaint(apiId);
      _complaints[index] = refreshed;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
