import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api/api_exception.dart';
import '../services/api/complaints_api.dart';
import 'auth_session.dart';
import 'complaint.dart';

class ComplaintsManager extends ChangeNotifier {
  static final ComplaintsManager _instance = ComplaintsManager._internal();
  factory ComplaintsManager() => _instance;
  ComplaintsManager._internal();

  static const _idsKeyPrefix = 'complaint_api_ids';
  static const _cacheKeyPrefix = 'complaint_cache';

  String _idsKey() {
    final userId = AuthSession.instance.user?.id;
    return userId != null ? '${_idsKeyPrefix}_$userId' : _idsKeyPrefix;
  }

  String _cacheKey() {
    final userId = AuthSession.instance.user?.id;
    return userId != null ? '${_cacheKeyPrefix}_$userId' : _cacheKeyPrefix;
  }

  final ComplaintsApi _api = ComplaintsApi();
  final List<Complaint> _complaints = [];
  bool _loading = false;
  String? _error;

  bool get isLoading => _loading;
  String? get error => _error;
  List<Complaint> get complaints => List.unmodifiable(_complaints);
  int get count => _complaints.length;

  /// يجلب الشكاوى من التخزين المحلي ثم يحدّثها عبر GET /api/complaints/{id}
  Future<void> syncFromApi() async {
    if (!AuthSession.instance.isAuthenticated) {
      _complaints.clear();
      _error = null;
      notifyListeners();
      return;
    }

    final cached = await _loadCache();
    final baseline = _mergeComplaints([...cached, ..._complaints]);
    if (baseline.isNotEmpty) {
      _complaints
        ..clear()
        ..addAll(baseline);
      notifyListeners();
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final ids = <int>{
        ...await _loadStoredIds(),
        for (final c in _mergeComplaints([...baseline, ..._complaints]))
          if (c.apiId != null) c.apiId!,
      };

      final fallback = {
        for (final c in _mergeComplaints([...baseline, ..._complaints]))
          if (c.apiId != null) c.apiId!: c,
      };

      final loaded = <Complaint>[];
      for (final id in ids) {
        try {
          loaded.add(await _api.fetchComplaint(id));
        } on ApiException catch (_) {
          final cachedOne = fallback[id];
          if (cachedOne != null) loaded.add(cachedOne);
        } catch (_) {
          final cachedOne = fallback[id];
          if (cachedOne != null) loaded.add(cachedOne);
        }
      }

      final merged = _mergeComplaints([...baseline, ..._complaints, ...loaded]);
      merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _complaints
        ..clear()
        ..addAll(merged);
      for (final c in merged) {
        if (c.apiId != null) await _rememberId(c.apiId!);
      }
      await _saveCache(_complaints);
    } on ApiException catch (e) {
      _error = e.message;
      if (_complaints.isEmpty && baseline.isNotEmpty) {
        _complaints.addAll(baseline);
      }
    } catch (e) {
      _error = e.toString();
      if (_complaints.isEmpty && baseline.isNotEmpty) {
        _complaints.addAll(baseline);
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// POST /api/complaints
  Future<bool> submitComplaint({
    required String category,
    required String subject,
    required String details,
    required int orderId,
    String priority = 'medium',
    List<XFile> attachments = const [],
    List<XFile> proof = const [],
  }) async {
    if (!AuthSession.instance.isAuthenticated) {
      _error = 'يجب تسجيل الدخول لإرسال شكوى';
      notifyListeners();
      return false;
    }

    _error = null;
    try {
      final files = await _buildMultipartFiles(
        attachments: attachments.take(5).toList(),
        proof: proof.take(5).toList(),
      );
      final created = await _api.createComplaint(
        orderId: orderId,
        category: category,
        subject: subject,
        description: details,
        priority: priority,
        attachments: files.attachments,
        proof: files.proof,
      );
      _complaints.insert(0, created);
      if (created.apiId != null) {
        await _rememberId(created.apiId!);
      }
      await _saveCache(_complaints);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = _formatApiError(e);
      notifyListeners();
      return false;
    } on FormatException catch (e) {
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
      await _saveCache(_complaints);
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

  Future<({List<http.MultipartFile> attachments, List<http.MultipartFile> proof})>
      _buildMultipartFiles({
    required List<XFile> attachments,
    required List<XFile> proof,
  }) async {
    final attachmentFiles = <http.MultipartFile>[];
    final proofFiles = <http.MultipartFile>[];

    for (var i = 0; i < attachments.length; i++) {
      final x = attachments[i];
      final bytes = await x.readAsBytes();
      final filename = x.name.isNotEmpty ? x.name : 'attachment_$i.jpg';
      attachmentFiles.add(
        http.MultipartFile.fromBytes(
          'attachments[$i]',
          bytes,
          filename: filename,
          contentType: _imageMediaType(filename),
        ),
      );
    }

    for (var i = 0; i < proof.length; i++) {
      final x = proof[i];
      final bytes = await x.readAsBytes();
      final filename = x.name.isNotEmpty ? x.name : 'proof_$i.jpg';
      proofFiles.add(
        http.MultipartFile.fromBytes(
          'proof[$i]',
          bytes,
          filename: filename,
          contentType: _imageMediaType(filename),
        ),
      );
    }

    return (attachments: attachmentFiles, proof: proofFiles);
  }

  String _formatApiError(ApiException e) {
    final fieldErrors = e.errors;
    if (fieldErrors != null && fieldErrors.isNotEmpty) {
      return fieldErrors.values.expand((messages) => messages).join('\n');
    }
    return e.message;
  }

  MediaType _imageMediaType(String filename) {
    final name = filename.toLowerCase();
    if (name.endsWith('.png')) return MediaType('image', 'png');
    if (name.endsWith('.gif')) return MediaType('image', 'gif');
    if (name.endsWith('.webp')) return MediaType('image', 'webp');
    if (name.endsWith('.bmp')) return MediaType('image', 'bmp');
    return MediaType('image', 'jpeg');
  }

  Future<List<int>> _loadStoredIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_idsKey()) ?? const [];
    return raw.map(int.tryParse).whereType<int>().where((id) => id > 0).toList();
  }

  Future<void> _rememberId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_idsKey()) ?? <String>[];
    final idStr = '$id';
    if (!current.contains(idStr)) {
      current.insert(0, idStr);
      await prefs.setStringList(_idsKey(), current);
    }
  }

  List<Complaint> _mergeComplaints(List<Complaint> items) {
    final byKey = <String, Complaint>{};
    for (final c in items) {
      final key = c.apiId != null
          ? 'api_${c.apiId}'
          : (c.id.isNotEmpty ? c.id : '${c.subject}_${c.createdAt.millisecondsSinceEpoch}');
      byKey[key] = c;
    }
    return byKey.values.toList();
  }

  Future<List<Complaint>> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey());
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => Complaint.fromApiJson(Map<String, dynamic>.from(e)))
          .where((c) => c.id.isNotEmpty || c.apiId != null)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _saveCache(List<Complaint> list) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = list.map((c) => c.toCacheJson()).toList();
    await prefs.setString(_cacheKey(), jsonEncode(payload));
  }
}
