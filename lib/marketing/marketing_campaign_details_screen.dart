import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_strings.dart';
import '../models/marketing_campaign.dart';
import '../utils/store_navigation.dart';
import '../widgets/store_cover_image.dart';
class MarketingCampaignDetailsScreen extends StatelessWidget {
  final MarketingCampaign campaign;

  const MarketingCampaignDetailsScreen({
    super.key,
    required this.campaign,
  });

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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (campaign.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: StoreCoverImage(
                      imageUrl: campaign.imageUrl!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                campaign.name,
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
                  _chip(context.tr(campaign.statusKey)),
                  ...campaign.storeKeys.map(
                    (key) => _chip('${context.tr('marketing_store')}: ${context.tr(key)}'),
                  ),
                  _chip('${context.tr('marketing_campaign_id')}: ${campaign.id}'),
                  _chip('${context.tr('marketing_campaign_period')}: ${_dateText(context, campaign.startAt)} → ${_dateText(context, campaign.endAt)}'),
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
                campaign.description ?? context.tr('marketing_no_content'),
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('campaign_participating_stores'),
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              ...campaign.storeKeys.map(
                (key) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => StoreNavigation.open(context, storeKey: key),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF3B82F6),
                        side: const BorderSide(color: const Color(0xFF3B82F6)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        context.tr(key),
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Text(
        text,
        style: GoogleFonts.cairo(fontSize: 12, color: Colors.white70),
      ),
    );
  }
}
