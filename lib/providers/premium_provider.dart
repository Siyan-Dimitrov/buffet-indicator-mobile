import 'package:flutter/foundation.dart';

import '../services/premium_service.dart';

/// State management for premium/free tier features.
class PremiumProvider extends ChangeNotifier {
  final PremiumService _service;

  PremiumProvider({PremiumService? service})
      : _service = service ?? PremiumService();

  bool get isPremium => _service.isPremium;
  String? get error => _service.error;
  String? get priceString => _service.product?.price;

  /// Free-tier investor profiles.
  static const freeProfiles = {'Warren Buffett', 'Benjamin Graham'};

  bool canUseProfile(String profileName) =>
      isPremium || freeProfiles.contains(profileName);

  bool get canUseTicker => isPremium;
  bool get canCompare => isPremium;
  int get historyLimit => isPremium ? -1 : 5; // -1 = unlimited

  Future<void> init() async {
    _service.onStatusChanged = () => notifyListeners();
    await _service.init();
    notifyListeners();
  }

  Future<void> purchase() async {
    await _service.purchase();
  }

  Future<void> restorePurchases() async {
    await _service.restorePurchases();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
