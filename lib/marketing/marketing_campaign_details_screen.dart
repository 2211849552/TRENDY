import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_strings.dart';
import '../models/marketing_campaign.dart';
import '../services/api/campaigns_api.dart';
import '../utils/store_navigation.dart';
import '../widgets/store_cover_image.dart';

class MarketingCampaignDetailsScreen extends StatefulWidget {
  final MarketingCampaign campaign;

  const MarketingCampaignDetailsScreen({
    super.key,
    required this.campaign,
  });

  @override
  State<MarketingCampaignDetailsScreen> createState() =>
      _MarketingCampaignDetailsScreenState();
}

class _MarketingCampaignDetailsScreenState
    extends State<MarketingCampaignDetailsScreen> {
  final CampaignsApi _api = CampaignsApi();
  late MarketingCampaign _campaign;
  bool _loadingStores = false;

  @override
  void initState() {
    super.initState();
    _campaign = widget.campaign;
    _loadCampaignDetails();
  }

  Future<void> _loadCampaignDetails() async {
    final id = int.tryParse(_campaign.id);
    if (id == null || id <= 0) return;

    setState(() => _loadingStores = true);
    try {
      final fresh = await _api.fetchCampaignById(id);
      if (!mounted || fresh == null) return;
      setState(() => _campaign = fresh);
    } catch (_) {
      // نُبقي بيانات القائمة إن فشل التفاصيل
    } finally {
      if (mounted) setState(() => _loadingStores = false);
    }
  }

  String _dateText(BuildContext context, DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: context.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            context.tr('marketing_ad_details'),
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _loadCampaignDetails,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_campaign.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: StoreCoverImage(
                        imageUrl: _campaign.imageUrl!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  _campaign.name,
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _chip(context.tr(_campaign.statusKey)),
                    _chip('${context.tr('marketing_campaign_id')}: ${_campaign.id}'),
                    _chip(
                      '${context.tr('marketing_campaign_period')}: ${_dateText(context, _campaign.startAt)} → ${_dateText(context, _campaign.endAt)}',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  context.tr('marketing_content'),
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _campaign.description ?? context.tr('marketing_no_content'),
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('campaign_participating_stores'),
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (_loadingStores)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_campaign.stores.isEmpty && !_loadingStores)
                  Text(
                    context.tr('campaign_no_participating_stores'),
                    style: GoogleFonts.cairo(color: Colors.white54, fontSize: 13),
                  )
                else
                  ..._campaign.stores.map(_storeButton),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _storeButton(CampaignStoreRef store) {
    final discount = store.discountPercentage?.trim();
    final label = discount != null && discount.isNotEmpty
        ? '${store.name} (-$discount%)'
        : store.name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () =>
              StoreNavigation.open(context, storeKey: store.navigationKey),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF3B82F6),
            side: const BorderSide(color: Color(0xFF3B82F6)),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: store.logoUrl.isEmpty
              ? const Icon(Icons.storefront_outlined, size: 22)
              : StoreCoverImage(
                  imageUrl: store.logoUrl,
                  asLogo: true,
                  width: 28,
                  height: 28,
                ),
          label: Text(
            label,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Text(
        text,
        style: GoogleFonts.cairo(fontSize: 12, color: Colors.white70),
      ),
    );
  }
}
