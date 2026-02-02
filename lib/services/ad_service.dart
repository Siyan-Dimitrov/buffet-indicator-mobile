import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Manages Google Mobile Ads initialization and ad unit IDs.
class AdService {
  // TODO: Replace with real AdMob IDs after creating your AdMob account.
  // These test IDs are provided by Google and will show test ads.
  static String get bannerAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Google test banner
    }
    // Replace with your real ad unit ID for release:
    return 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';
  }

  static Future<void> init() async {
    await MobileAds.instance.initialize();
  }
}
