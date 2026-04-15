import 'package:flutter/material.dart';
import 'complaint.dart';

class ComplaintsManager extends ChangeNotifier {
  static final ComplaintsManager _instance = ComplaintsManager._internal();
  factory ComplaintsManager() => _instance;
  ComplaintsManager._internal();

  final List<Complaint> _complaints = [];

  List<Complaint> get complaints => List.unmodifiable(_complaints);

  void addComplaint(Complaint complaint) {
    _complaints.insert(0, complaint);
    notifyListeners();
  }

  void addReply({
    required String complaintId,
    required String message,
    bool isFromUser = true,
  }) {
    final i = _complaints.indexWhere((c) => c.id == complaintId);
    if (i < 0) return;
    _complaints[i].replies.add(
      ComplaintReply(
        message: message,
        date: DateTime.now(),
        isFromUser: isFromUser,
      ),
    );
    if (isFromUser) {
      _complaints[i].statusKey = 'complaint_status_open';
    }
    notifyListeners();
  }

  void closeComplaint(String complaintId) {
    final i = _complaints.indexWhere((c) => c.id == complaintId);
    if (i < 0) return;
    _complaints[i].statusKey = 'complaint_status_closed';
    notifyListeners();
  }
}
