import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_strings.dart';
import '../models/marketing_campaign.dart';
import '../models/marketing_campaigns_manager.dart';
import 'marketing_campaign_details_screen.dart';

class MarketingCampaignsScreen extends StatefulWidget {
  const MarketingCampaignsScreen({super.key});

  @override
  State<MarketingCampaignsScreen> createState() => _MarketingCampaignsScreenState();
}

class _MarketingCampaignsScreenState extends State<MarketingCampaignsScreen> {
  final _manager = MarketingCampaignsManager();
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String _statusFilter = 'campaign_status_all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<MarketingCampaign> get _filtered {
    final q = _query.trim().toLowerCase();
    final items = _manager.campaigns.where((c) {
      final matchesName = q.isEmpty ? true : c.name.toLowerCase().contains(q);
      final matchesStatus = _statusFilter == 'campaign_status_all' ? true : c.statusKey == _statusFilter;
      return matchesName && matchesStatus;
    }).toList();

    // Newest first
    items.sort((a, b) => b.startAt.compareTo(a.startAt));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: context.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            context.tr('marketing_title'),
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchAndFilters(context),
              const SizedBox(height: 16),
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text(
                          context.tr('marketing_empty'),
                          style: GoogleFonts.cairo(color: Colors.white54),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => _CampaignCard(
                          campaign: _filtered[i],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MarketingCampaignDetailsScreen(campaign: _filtered[i]),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _search,
          style: GoogleFonts.cairo(color: Colors.white),
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: context.tr('marketing_search_hint'),
            hintStyle: GoogleFonts.cairo(color: Colors.white38, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _dropdown(
                context: context,
                value: _statusFilter,
                items: const [
                  'campaign_status_all',
                  'campaign_status_active',
                  'campaign_status_planned',
                  'campaign_status_paused',
                  'campaign_status_ended',
                  'campaign_status_draft',
                ],
                labelFor: (k) => context.tr(k),
                onChanged: (v) => setState(() => _statusFilter = v ?? 'campaign_status_all'),
                icon: Icons.filter_alt_outlined,
                title: context.tr('marketing_filter_status'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dropdown({
    required BuildContext context,
    required String value,
    required List<String> items,
    required String Function(String) labelFor,
    required void Function(String?) onChanged,
    required String title,
    required IconData icon,
  }) {
    final align = context.isRtl ? Alignment.centerRight : Alignment.centerLeft;
    final tAlign = context.isRtl ? TextAlign.right : TextAlign.left;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                dropdownColor: const Color(0xFF0A1931),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                isExpanded: true,
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
                items: items
                    .map(
                      (k) => DropdownMenuItem(
                        value: k,
                        child: Align(
                          alignment: align,
                          child: Text(labelFor(k), textAlign: tAlign),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final MarketingCampaign campaign;
  final VoidCallback onTap;

  const _CampaignCard({
    required this.campaign,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 74,
                height: 74,
                color: Colors.white10,
                child: campaign.imageUrl == null
                    ? const Icon(Icons.campaign_outlined, color: Colors.white30, size: 30)
                    : Image.network(
                        campaign.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image_outlined, color: Colors.white30, size: 30);
                        },
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${context.tr('marketing_store')}: ${context.tr(campaign.storeKey)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _statusPill(context.tr(campaign.statusKey)),
                      const SizedBox(width: 8),
                      Text(
                        campaign.id,
                        style: GoogleFonts.cairo(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white30),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        text,
        style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

