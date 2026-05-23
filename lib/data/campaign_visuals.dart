import 'package:flutter/material.dart';



/// ألوان وصور كل حملة إعلانية — ثيم بودري موحّد للحملات النشطة.

class CampaignVisuals {

  CampaignVisuals._();



  static const _powderPink = CampaignVisual(

    imageUrl: null,

    accent: Color(0xFFC084FC),

    accentSoft: Color(0x33A855F7),

    gradientStart: Color(0xFF2D2A52),

    gradientEnd: Color(0xFF121026),

    badgeColor: Color(0xFFA855F7),

  );



  static const _default = CampaignVisual(

    imageUrl: null,

    accent: Color(0xFFC084FC),

    accentSoft: Color(0x33A855F7),

    gradientStart: Color(0xFF2D2A52),

    gradientEnd: Color(0xFF121026),

    badgeColor: Color(0xFFA855F7),

  );



  static String? _imageFor(String campaignId) {

    switch (campaignId) {

      case 'cmp_001':

        return 'assets/images/campaigns/cmp_white_friday.png';

      case 'cmp_002':

        return 'assets/images/campaigns/cmp_first_order.png';

      case 'cmp_003':

        return 'assets/images/campaigns/cmp_end_season.png';

      default:

        return null;

    }

  }



  static CampaignVisual forCampaign(String campaignId) {

    final imageUrl = _imageFor(campaignId);

    if (imageUrl == null) return _default;

    return CampaignVisual(

      imageUrl: imageUrl,

      accent: _powderPink.accent,

      accentSoft: _powderPink.accentSoft,

      gradientStart: _powderPink.gradientStart,

      gradientEnd: _powderPink.gradientEnd,

      badgeColor: _powderPink.badgeColor,

    );

  }



  static const sectionGradient = LinearGradient(

    begin: Alignment.topRight,

    end: Alignment.bottomLeft,

    colors: [

      Color(0xFF2D2A52),

      Color(0xFF121026),

      Color(0xFF1E1B4B),

    ],

  );



  static const sectionBorder = Color(0x40A855F7);

  static const sectionGlow = Color(0x18A855F7);

}



class CampaignVisual {

  final String? imageUrl;

  final Color accent;

  final Color accentSoft;

  final Color gradientStart;

  final Color gradientEnd;

  final Color badgeColor;



  const CampaignVisual({

    required this.imageUrl,

    required this.accent,

    required this.accentSoft,

    required this.gradientStart,

    required this.gradientEnd,

    required this.badgeColor,

  });



  LinearGradient get cardGradient => LinearGradient(

        begin: Alignment.topRight,

        end: Alignment.bottomLeft,

        colors: [gradientStart, gradientEnd],

      );



  LinearGradient get imageOverlay => LinearGradient(

        begin: Alignment.topCenter,

        end: Alignment.bottomCenter,

        colors: [

          Colors.transparent,

          gradientEnd.withValues(alpha: 0.85),

        ],

      );

}


