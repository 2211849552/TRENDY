import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_strings.dart';
import '../models/delivery_zone.dart';
import '../services/api/api_exception.dart';
import '../services/api/zones_api.dart';
import '../theme/app_colors.dart';
import '../theme/trendy_theme_extension.dart';
import 'app_back_button.dart';

/// شاشة اختيار منطقة التوصيل من القائمة المحددة بالإدارة (GET /api/zones).
class ZonePickerScreen extends StatefulWidget {
  const ZonePickerScreen({super.key, this.selectedZoneId});

  final int? selectedZoneId;

  @override
  State<ZonePickerScreen> createState() => _ZonePickerScreenState();
}

class _ZonePickerScreenState extends State<ZonePickerScreen> {
  final ZonesApi _api = ZonesApi();
  final TextEditingController _search = TextEditingController();

  List<DeliveryZone> _zones = const [];
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadZones() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final zones = await _api.fetchZones();
      if (!mounted) return;
      setState(() => _zones = zones);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = context.tr('addr_zone_load_failed'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<DeliveryZone> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _zones;
    return _zones.where((z) => z.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.trendy;

    return Scaffold(
      backgroundColor: t.pageBackground,
      body: SafeArea(
        child: Directionality(
          textDirection: context.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  children: [
                    AppBackIconButton(onPressed: () => Navigator.pop(context)),
                    const Spacer(),
                    Text(
                      context.tr('addr_select_zone_title'),
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: t.titleColor,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  context.tr('addr_select_zone_sub'),
                  style: GoogleFonts.cairo(color: t.subtitleColor, fontSize: 14),
                ),
              ),
              if (_zones.length > 4) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    style: GoogleFonts.cairo(color: t.titleColor),
                    decoration: InputDecoration(
                      hintText: context.tr('addr_zone_search_hint'),
                      hintStyle: GoogleFonts.cairo(color: t.hintColor),
                      prefixIcon: Icon(Icons.search_rounded, color: t.hintColor),
                      filled: true,
                      fillColor: t.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: t.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: t.cardBorder),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Expanded(child: _buildBody(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final t = context.trendy;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(color: t.subtitleColor),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _loadZones,
                child: Text(context.tr('retry'), style: GoogleFonts.cairo()),
              ),
            ],
          ),
        ),
      );
    }
    if (_zones.isEmpty) {
      return Center(
        child: Text(
          context.tr('addr_zone_empty'),
          style: GoogleFonts.cairo(color: t.subtitleColor, fontSize: 15),
        ),
      );
    }

    final list = _filtered;
    if (list.isEmpty) {
      return Center(
        child: Text(
          context.tr('search_no_result'),
          style: GoogleFonts.cairo(color: t.subtitleColor),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final zone = list[index];
        final selected = widget.selectedZoneId == zone.id;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pop(context, zone),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: t.cardFill.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppColors.primary : t.cardBorder,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _formatZoneName(zone.name),
                      style: GoogleFonts.cairo(
                        color: t.titleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    context.isRtl ? Icons.chevron_left : Icons.chevron_right,
                    color: t.hintColor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatZoneName(String raw) {
    if (raw.isEmpty) return raw;
    return raw[0].toUpperCase() + raw.substring(1);
  }
}
