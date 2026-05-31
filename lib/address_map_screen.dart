import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import 'l10n/app_strings.dart';
import 'models/addresses_manager.dart';
import 'theme/app_colors.dart';
import 'widgets/app_back_button.dart';
import 'widgets/schematic_map_tiles.dart';

class AddressMapScreen extends StatefulWidget {
  const AddressMapScreen({super.key, this.initial});

  final SavedAddress? initial;

  @override
  State<AddressMapScreen> createState() => _AddressMapScreenState();
}

class _AddressMapScreenState extends State<AddressMapScreen> {
  final MapController _mapController = MapController();

  late double _lat;
  late double _lng;
  late String _streetLine;
  late String _city;
  bool _locating = false;
  bool _isLightMap = false;
  bool _isSatellite = false;
  LatLng? _userPosition;

  static const _satelliteTemplate =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
  static const _satelliteFallback =
      'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _lat = init?.lat ?? AddressesManager.defaultLat;
    _lng = init?.lng ?? AddressesManager.defaultLng;
    _streetLine = init?.streetLine ?? '';
    _city = init?.city ?? '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_streetLine.isEmpty) _streetLine = context.tr('addr_default_street');
    if (_city.isEmpty) _city = context.tr('addr_default_city');
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _syncCenterFromMap() {
    final center = _mapController.camera.center;
    setState(() {
      _lat = center.latitude;
      _lng = center.longitude;
    });
  }

  void _toggleLightDark() {
    if (_isSatellite) setState(() => _isSatellite = false);
    setState(() => _isLightMap = !_isLightMap);
  }

  void _toggleSatellite() {
    setState(() => _isSatellite = !_isSatellite);
  }

  TileLayer _buildTileLayer() {
    if (_isSatellite) {
      return TileLayer(
        key: const ValueKey('satellite'),
        urlTemplate: _satelliteTemplate,
        fallbackUrl: _satelliteFallback,
        tileProvider: NetworkTileProvider(),
        userAgentPackageName: 'com.trendy.app',
        retinaMode: false,
        maxNativeZoom: 19,
        maxZoom: 19,
      );
    }
    return TileLayer(
      key: ValueKey('schematic_${_isLightMap ? 'sun' : 'moon'}'),
      urlTemplate: 'schematic://{z}/{x}/{y}',
      tileProvider: SchematicTileProvider(isLight: _isLightMap),
      retinaMode: false,
      maxNativeZoom: 18,
      maxZoom: 18,
    );
  }

  Future<void> _locateMe() async {
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('addr_location_service_off'), style: GoogleFonts.cairo()),
            ),
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('addr_location_denied'), style: GoogleFonts.cairo())),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (!mounted) return;

      final point = LatLng(pos.latitude, pos.longitude);
      _mapController.move(point, 17);
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _userPosition = point;
        _streetLine = context.tr('addr_current_location');
        _city = context.tr('addr_default_city');
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('addr_location_failed'), style: GoogleFonts.cairo())),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _continue() {
    Navigator.pop(
      context,
      SavedAddress(
        id: widget.initial?.id ?? '',
        label: widget.initial?.label ?? '',
        streetLine: _streetLine,
        city: _city,
        description: widget.initial?.description,
        lat: _lat,
        lng: _lng,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isSatellite
          ? const Color(0xFF0D1117)
          : (_isLightMap ? const Color(0xFFE9EDF2) : const Color(0xFF1A212B)),
      body: Directionality(
        textDirection: context.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Stack(
          children: [
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(_lat, _lng),
                  initialZoom: 16.5,
                  minZoom: 5,
                  maxZoom: 19,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                  onMapEvent: (event) {
                    if (event is MapEventMoveEnd || event is MapEventFlingAnimationEnd) {
                      _syncCenterFromMap();
                    }
                  },
                ),
                children: [
                  _buildTileLayer(),
                  if (_userPosition != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _userPosition!,
                          width: 22,
                          height: 22,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF4285F4),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4285F4).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            SafeArea(
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: AppBackIconButton(
                      iconSize: 22,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AddressConfirmedBubble(
                    title: context.tr('addr_confirmed'),
                    subtitle: context.tr('addr_will_deliver'),
                  ),
                  const SizedBox(height: 8),
                  const _MapPin(),
                ],
              ),
            ),
            PositionedDirectional(
              end: 16,
              bottom: 200,
              child: Column(
                children: [
                  _MapFab(
                    icon: _isLightMap ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
                    active: _isLightMap,
                    onTap: _toggleLightDark,
                  ),
                  const SizedBox(height: 10),
                  _MapFab(
                    icon: Icons.public,
                    active: _isSatellite,
                    onTap: _toggleSatellite,
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(28),
                    child: InkWell(
                      onTap: _locating ? null : _locateMe,
                      borderRadius: BorderRadius.circular(28),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_locating)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            else
                              const Icon(Icons.my_location, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              context.tr('locate_me_auto'),
                              style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: Colors.white, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _streetLine,
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _city,
                                  style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _continue,
                              borderRadius: BorderRadius.circular(12),
                              child: Center(
                                child: Text(
                                  context.tr('continue_btn'),
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressConfirmedBubble extends StatelessWidget {
  const _AddressConfirmedBubble({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.location_on, color: Colors.white, size: 18),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFFE53935),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.sentiment_satisfied_alt, color: Colors.white, size: 26),
        ),
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFFE53935).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Container(
          width: 14,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      ],
    );
  }
}

class _MapFab extends StatelessWidget {
  const _MapFab({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.primary.withValues(alpha: 0.85) : Colors.black.withValues(alpha: 0.65),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
