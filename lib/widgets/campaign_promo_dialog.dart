import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/campaign_visuals.dart';
import '../l10n/app_strings.dart';
import '../models/marketing_campaign.dart';
import '../utils/store_navigation.dart';
import 'store_cover_image.dart';

class CampaignPromoDialog extends StatelessWidget {
  final MarketingCampaign campaign;
  final double? userLat;
  final double? userLng;

  const CampaignPromoDialog({
    super.key,
    required this.campaign,
    this.userLat,
    this.userLng,
  });

  static Future<void> show(
    BuildContext context, {
    required MarketingCampaign campaign,
    double? userLat,
    double? userLng,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => CampaignPromoDialog(
        campaign: campaign,
        userLat: userLat,
        userLng: userLng,
      ),
    );
  }

  String _dateText(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y/$m/$day';
  }

  void _visitStore(BuildContext context, String storeKey) {
    Navigator.of(context).pop();
    StoreNavigation.open(
      context,
      storeKey: storeKey,
      userLat: userLat,
      userLng: userLng,
    );
  }

  Widget _buildFullImage(BuildContext context, String imageUrl) {
    final maxH = MediaQuery.sizeOf(context).height * 0.55;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: Colors.black26,
        child: SizedBox(
          width: double.infinity,
          height: maxH,
          child: InteractiveViewer(
            minScale: 0.85,
            maxScale: 3.5,
            child: Center(
              child: StoreCoverImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: maxH,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visual = CampaignVisuals.forCampaign(campaign.id);
    final imageUrl = campaign.imageUrl;
    final screenW = MediaQuery.sizeOf(context).width;

    return Directionality(
      textDirection: context.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: visual.gradientEnd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: visual.accent.withValues(alpha: 0.5)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: screenW > 600 ? 480 : screenW - 32),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white54),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  if (imageUrl != null) ...[
                    _buildFullImage(context, imageUrl),
                    const SizedBox(height: 14),
                  ],
                  Text(
                    campaign.name,
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('campaign_participating_stores'),
                    style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  if (campaign.stores.isEmpty)
                    Text(
                      context.tr('campaign_no_participating_stores'),
                      style: GoogleFonts.cairo(color: Colors.white38, fontSize: 12),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: campaign.stores.map((store) {
                        final discount = store.discountPercentage?.trim();
                        final label = discount != null && discount.isNotEmpty
                            ? '${store.name} (-$discount%)'
                            : store.name;
                        return ActionChip(
                          avatar: store.logoUrl.isEmpty
                              ? null
                              : StoreCoverImage(
                                  imageUrl: store.logoUrl,
                                  asLogo: true,
                                  width: 22,
                                  height: 22,
                                ),
                          label: Text(label, style: GoogleFonts.cairo(fontSize: 12)),
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                          ),
                          labelStyle: const TextStyle(color: Colors.white),
                          onPressed: () => _visitStore(context, store.navigationKey),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    campaign.description ?? context.tr('marketing_no_content'),
                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${context.tr('campaign_from')} ${_dateText(campaign.startAt)} ${context.tr('campaign_to')} ${_dateText(campaign.endAt)}',
                    style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
