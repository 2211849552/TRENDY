#!/usr/bin/env python3
"""
تحميل صور ملابس محلية — صورة واحدة فريدة لكل منتج تطابق اسمه.
تشغيل: python tool/download_product_assets.py
"""
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "images" / "products"

# كل منتج → معرّف Pexels فريد (ملابس فقط، بدون أحذية/حقائب/ساعات)
PRODUCT_PHOTO_ID: dict[str, int] = {
    # ── متجر الأناقة ──
    "prod_wrap_midi_dress": 1572801,       # فستان لف ميدي
    "prod_satin_blouse": 1021693,          # بلوزة ساتان
    "prod_linen_blazer": 768767,           # بليزر كتان
    "prod_high_waist_trousers": 7679087,   # بنطال خصر عالي
    "prod_cotton_cardigan": 6065199,       # كارديغان قطني
    "prod_maxi_dress_flowy": 1535200,      # فستان ماكسي
    "prod_striped_button_shirt": 2983468,  # قميص مخطط
    "prod_pleated_skirt": 1007018,         # تنورة بليسيه
    "prod_ribbed_knit_top": 6065198,       # بلوزة محبوكة مضلعة
    # ── متجر الفخامة ──
    "prod_evening_gown": 1926769,          # فستان سهرة
    "prod_lux_silk_blouse": 6311397,       # بلوزة حرير فاخرة
    "prod_satin_skirt": 983192,            # تنورة ساتان
    "prod_lux_tailored_pants": 6311673,    # بنطال مفصل
    "prod_lux_midi_dress": 206359,         # فستان ميدي فاخر
    "prod_lux_cashmere_coat": 6311394,     # معطف كشمير
    "prod_signature_blazer": 6311472,      # بليزر بتصميم خاص
    "prod_lux_trench_coat": 1124469,       # ترانش كوت فاخر
    "prod_lux_white_blouse": 985635,       # بلوزة بيضاء فاخرة
    # ── الرجل الأنيق ──
    "prod_wool_suit": 1653823,             # بدلة صوف رسمية
    "prod_oxford_shirt": 297933,           # قميص أوكسفورد
    "prod_slim_chinos": 1598505,           # بنطال تشينو سليم
    "prod_formal_pants": 7687250,          # بنطال رسمي
    "prod_polo_knit": 7691095,             # بولو محبوك
    "prod_navy_blazer": 3760850,           # بليزر كحلي
    "prod_white_shirt_formal": 428338,     # قميص أبيض رسمي
    "prod_knit_sweater_men": 6065202,      # كنزة رجالية
    "prod_wool_overcoat": 9859352,         # معطف صوف طويل
    # ── بوتيك الموضة ──
    "prod_basic_tshirt": 297934,           # تيشيرت أساسي
    "prod_denim_jacket_m": 6843241,        # جاكيت جينز رجالي (لقطة قريبة)
    "prod_hoodie_fleece": 7671166,         # هودي فليس
    "prod_slim_jeans": 1541090,            # جينز سليم
    "prod_relaxed_jeans": 1598507,         # جينز واسع
    "prod_puffer_jacket": 6311652,         # جاكيت بَفَر
    "prod_bomber_jacket": 1040945,         # جاكيت بومبر
    "prod_graphic_tee": 1916824,           # تيشيرت برسمة
    "prod_track_pants": 6311653,           # بنطال رياضي
    # ── عالم الأطفال ──
    "prod_kids_hoodie": 3608295,           # هودي أطفال
    "prod_kids_denim": 3553375,            # جينز أطفال
    "prod_kids_jeans": 3553377,            # بنطال جينز أطفال
    "prod_kids_dress_cotton": 3553374,     # فستان قطن أطفال
    "prod_kids_set_sport": 3553381,        # طقم رياضي أطفال
    "prod_kids_dress_party": 6311480,      # فستان مناسبات أطفال
    "prod_kids_jacket_light": 3553376,     # جاكيت خفيف أطفال
    "prod_kids_sweater": 6065204,          # سويتر أطفال
    "prod_kids_tracksuit": 3553380,        # بدلة رياضية أطفال
    # ── توب فاشن ──
    "prod_trench_coat": 1124466,           # ترانش كوت
    "prod_knit_sweater": 6065205,          # كنزة محبوكة
    "prod_oversized_hoodie": 7671169,      # هودي أوفرسايز
    "prod_long_sleeve_tee": 994523,         # تيشيرت كم طويل
    "prod_joggers": 7679084,               # بنطال جوجرز
    "prod_windbreaker_jacket": 6311390,    # جاكيت ويند بريكر
    "prod_black_jeans": 1126993,           # جينز أسود
    "prod_sweatshirt_basic": 7671168,      # سويت شيرت
    "prod_denim_jacket_classic": 6769347,  # جاكيت جينز كلاسيكي
}

# مسارات خاصة لا تُستبدل بملف .jpg افتراضي
CATALOG_OVERRIDES: dict[str, str] = {
    "prod_polo_knit": "assets/images/products/prod_polo_knit_green.png",
    "prod_maxi_dress_flowy": "assets/images/products/prod_maxi_dress_flowy.png",
    "prod_kids_dress_party": "assets/images/products/prod_kids_dress_party.png",
    # متجر الرجل الأنيق — صور مخصصة (PNG)
    "prod_gentle_shirt_1": "assets/images/products/prod_gentle_shirt_1.png",
    "prod_gentle_shirt_2": "assets/images/products/prod_gentle_shirt_2.png",
    "prod_gentle_tshirt_1": "assets/images/products/prod_gentle_tshirt_1.png",
    "prod_gentle_tshirt_2": "assets/images/products/prod_gentle_tshirt_2.png",
    "prod_gentle_pants_1": "assets/images/products/prod_gentle_pants_1.png",
    "prod_gentle_pants_2": "assets/images/products/prod_gentle_pants_2.png",
    "prod_gentle_shorts_1": "assets/images/products/prod_gentle_shorts_1.png",
    "prod_gentle_shorts_2": "assets/images/products/prod_gentle_shorts_2.png",
    "prod_gentle_jacket_1": "assets/images/products/prod_gentle_jacket_1.png",
    "prod_gentle_jacket_2": "assets/images/products/prod_gentle_jacket_2.png",
}


def pexels_url(photo_id: int) -> str:
    return (
        f"https://images.pexels.com/photos/{photo_id}/"
        f"pexels-photo-{photo_id}.jpeg?auto=compress&cs=tinysrgb&w=600"
    )


def fetch(photo_id: int) -> bytes:
    url = pexels_url(photo_id)
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (TRENDY)"})
    with urllib.request.urlopen(req, timeout=45) as resp:
        data = resp.read()
    if len(data) < 3000:
        raise ValueError(f"صورة صغيرة جداً: {photo_id}")
    return data


def main() -> None:
    ids = list(PRODUCT_PHOTO_ID.values())
    if len(ids) != len(set(ids)):
        dup = {x for x in ids if ids.count(x) > 1}
        raise SystemExit(f"معرّفات مكررة — يجب أن تكون كل صورة فريدة: {dup}")

    OUT.mkdir(parents=True, exist_ok=True)
    lines = [
        "/// صور ملابس محلية — كل منتج له صورة ملابس محلية (بدون إنترنت عند التشغيل).",
        "const Map<String, String> kProductImageCatalog = {",
    ]

    for key, photo_id in PRODUCT_PHOTO_ID.items():
        override = CATALOG_OVERRIDES.get(key)
        if override is not None:
            lines.append(f"  '{key}': '{override}',")
            print(f"SKIP {key} (override)")
            continue
        data = fetch(photo_id)
        (OUT / f"{key}.jpg").write_bytes(data)
        lines.append(f"  '{key}': 'assets/images/products/{key}.jpg',")
        print(f"OK  {key} <- {photo_id}")

    for key, path in CATALOG_OVERRIDES.items():
        if key in PRODUCT_PHOTO_ID:
            continue
        lines.append(f"  '{key}': '{path}',")
        print(f"KEEP {key} -> {path}")

    lines.append("};")
    catalog = ROOT / "lib" / "data" / "product_image_catalog.dart"
    catalog.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"\nDone: {len(PRODUCT_PHOTO_ID)} images -> {catalog}")


if __name__ == "__main__":
    main()
