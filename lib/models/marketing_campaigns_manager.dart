import 'package:flutter/foundation.dart';

import '../services/api/campaigns_api.dart';
import 'marketing_campaign.dart';

/// إدارة قائمة الحملات — من GET /api/campaigns فقط (حسب api.md).
class MarketingCampaignsManager extends ChangeNotifier {
  MarketingCampaignsManager._();
  static final MarketingCampaignsManager _instance = MarketingCampaignsManager._();
  factory MarketingCampaignsManager() => _instance;

  final CampaignsApi _api = CampaignsApi();
  bool _isLoading = false;
  String? _loadError;

  List<MarketingCampaign> _campaigns = [];

  bool get isLoading => _isLoading;
  String? get loadError => _loadError;

  List<MarketingCampaign> get campaigns => List.unmodifiable(_campaigns);

  List<MarketingCampaign> get homeFeatured {
    final source = _campaigns
        .where((c) => c.statusKey == 'campaign_status_active')
        .toList();
    source.sort((a, b) => b.startAt.compareTo(a.startAt));
    return source.take(3).toList();
  }

  Future<void> loadFromApi({int limit = 50}) async {
    if (_isLoading) return;
    _isLoading = true;
    _loadError = null;
    notifyListeners();
    try {
      final items = await _api.fetchActiveCampaigns(limit: limit);
      _campaigns = items;
    } catch (e) {
      _campaigns = [];
      _loadError = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
