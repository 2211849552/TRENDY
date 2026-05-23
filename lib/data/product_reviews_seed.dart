import 'product_image_catalog.dart';
import '../models/customer_review.dart';

/// تعليقات وصور افتراضية من زبائن سابقين لكل منتج.
class ProductReviewsSeed {
  ProductReviewsSeed._();

  static final Map<String, List<CustomerReview>> _byProduct = {
    'prod_gentle_shirt_1': _shirtReviews,
    'prod_gentle_pants_1': _pantsReviews,
    'prod_gentle_jacket_1': _jacketReviews,
    'prod_wool_suit': _suitReviews,
    'prod_formal_pants': _pantsReviews,
    'prod_evening_gown': _dressReviews,
    'prod_wrap_midi_dress': _dressReviews,
    'prod_lux_midi_dress': _dressReviews,
  };

  static final _shirtReviews = [
    CustomerReview(
      authorName: 'أحمد م.',
      rating: 5,
      comment: 'قماش ممتاز وقصة مريحة، مناسب للعمل والخروجات.',
      imageAssetPath: 'assets/images/products/prod_gentle_shirt_1.png',
      date: _d(2026, 4, 8),
    ),
    CustomerReview(
      authorName: 'سامي ح.',
      rating: 4,
      comment: 'اللون ثابت بعد الغسيل، المقاس مطابق للجدول.',
      date: _d(2026, 3, 2),
    ),
  ];

  static final _jacketReviews = [
    CustomerReview(
      authorName: 'خالد س.',
      rating: 5,
      comment: 'جاكيت أنيق وخفيف، مثالي للخريف والشتاء الخفيف.',
      imageAssetPath: 'assets/images/products/prod_gentle_jacket_1.png',
      date: _d(2026, 4, 15),
    ),
    CustomerReview(
      authorName: 'يوسف ع.',
      rating: 4,
      comment: 'جودة الخياطة ممتازة، أنصح بأخذ مقاس أكبر للراحة.',
      date: _d(2026, 2, 22),
    ),
  ];

  static final _suitReviews = [
    CustomerReview(
      authorName: 'أحمد م.',
      rating: 5,
      comment: 'جودة القماش ممتازة والقصة أنيقة جداً. أنصح بها للمناسبات الرسمية.',
      imageAssetPath: 'assets/images/products/prod_wool_suit.jpg',
      date: _d(2026, 4, 12),
    ),
    CustomerReview(
      authorName: 'خالد س.',
      rating: 4,
      comment: 'البدلة جميلة والمقاس S مناسب. التوصيل كان سريعاً.',
      date: _d(2026, 3, 28),
    ),
    CustomerReview(
      authorName: 'يوسف ع.',
      rating: 5,
      comment: 'تجربة شراء ممتازة، اللون أسود كما في الصورة تماماً.',
      imageAssetPath: 'assets/images/products/prod_white_shirt_formal.jpg',
      date: _d(2026, 2, 5),
    ),
  ];

  static final _pantsReviews = [
    CustomerReview(
      authorName: 'محمد ر.',
      rating: 4,
      comment: 'بنطال مريح للعمل اليومي، الخياطة محكمة.',
      imageAssetPath: 'assets/images/products/prod_gentle_pants_1.png',
      date: _d(2026, 4, 1),
    ),
    CustomerReview(
      authorName: 'عمر ل.',
      rating: 5,
      comment: 'أفضل بنطال اشتريته هذا العام، المقاس دقيق.',
      date: _d(2026, 1, 18),
    ),
  ];

  static final _dressReviews = [
    CustomerReview(
      authorName: 'سارة ح.',
      rating: 5,
      comment: 'فستان رائع وخفيف، لبسته في حفل زفاف وكان مذهلاً.',
      imageAssetPath: 'assets/images/products/prod_evening_gown.jpg',
      date: _d(2026, 5, 2),
    ),
    CustomerReview(
      authorName: 'نورا ك.',
      rating: 4,
      comment: 'الخامة جيدة والتفاصيل أنيقة. أنصح بأخذ مقاس أكبر إن كنت تفضلين الراحة.',
      date: _d(2026, 3, 10),
    ),
  ];

  static List<CustomerReview> reviewsFor(String productKey) {
    final specific = _byProduct[productKey];
    if (specific != null) return List<CustomerReview>.from(specific);
    return _genericReviews(productKey);
  }

  static List<CustomerReview> _genericReviews(String productKey) {
    final img = kProductImageCatalog[productKey];
    return [
      CustomerReview(
        authorName: 'ليلى م.',
        rating: 5,
        comment: 'منتج جميل ومطابق للوصف، سأطلبه مرة أخرى بإذن الله.',
        imageAssetPath: img,
        date: _d(2026, 4, 20),
      ),
      CustomerReview(
        authorName: 'فاطمة ع.',
        rating: 4,
        comment: 'تجربة شراء جيدة، الجودة تستحق السعر.',
        date: _d(2026, 3, 15),
      ),
      CustomerReview(
        authorName: 'مريم س.',
        rating: 5,
        comment: 'أعجبني التغليف والتوصيل السريع. المنتج كما في الصورة.',
        imageAssetPath: img,
        date: _d(2026, 2, 8),
      ),
    ];
  }

  static DateTime _d(int y, int m, int d) => DateTime(y, m, d);
}
