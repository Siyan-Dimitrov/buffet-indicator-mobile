import 'package:hive_flutter/hive_flutter.dart';

import '../models/sec_company.dart';

/// Hive-based local cache for SEC company tickers.
///
/// Caches ~13,000 tickers locally for fast offline search.
/// Refreshes every 7 days.
class TickerCacheService {
  static const String _boxName = 'ticker_cache';
  static const String _tickersKey = 'tickers';
  static const String _lastUpdatedKey = 'last_updated';
  static const Duration _cacheExpiry = Duration(days: 7);

  late Box<dynamic> _box;
  List<SecCompany> _tickers = [];

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _loadFromCache();
  }

  void _loadFromCache() {
    final cached = _box.get(_tickersKey) as List<dynamic>?;
    if (cached != null) {
      _tickers = cached
          .map((json) => SecCompany.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
  }

  bool get isCacheValid {
    final lastUpdated = _box.get(_lastUpdatedKey) as DateTime?;
    if (lastUpdated == null) return false;
    return DateTime.now().difference(lastUpdated) < _cacheExpiry;
  }

  Future<void> updateCache(List<SecCompany> tickers) async {
    _tickers = tickers;
    await _box.put(_tickersKey, tickers.map((t) => t.toJson()).toList());
    await _box.put(_lastUpdatedKey, DateTime.now());
  }

  /// Search tickers locally. Results are ranked:
  /// 1. Exact ticker match
  /// 2. Ticker starts with query
  /// 3. Company name contains query
  List<SecCompany> search(String query, {int limit = 10}) {
    if (query.isEmpty) return [];

    final upperQuery = query.toUpperCase();
    final lowerQuery = query.toLowerCase();

    final exactMatch =
        _tickers.where((t) => t.ticker == upperQuery);

    final tickerStarts = _tickers.where(
        (t) => t.ticker.startsWith(upperQuery) && t.ticker != upperQuery);

    final nameContains = _tickers.where((t) =>
        t.name.toLowerCase().contains(lowerQuery) &&
        !t.ticker.startsWith(upperQuery));

    return [...exactMatch, ...tickerStarts, ...nameContains]
        .take(limit)
        .toList();
  }

  int get tickerCount => _tickers.length;
}
