import 'package:flutter/foundation.dart';

import '../models/sec_company.dart';
import '../models/sec_financial_data.dart';
import '../services/sec_api_service.dart';
import '../services/stock_price_service.dart';
import '../services/ticker_cache_service.dart';

/// State management for SEC EDGAR API features.
class SecProvider extends ChangeNotifier {
  final SecApiService _apiService;
  final StockPriceService _stockPriceService;
  final TickerCacheService _cacheService;

  List<SecCompany> _searchResults = [];
  SecCompany? _selectedCompany;
  SecFinancialData? _financialData;
  bool _isLoading = false;
  bool _isCacheLoading = false;
  String? _error;
  String? _stockPriceError;

  SecProvider({
    SecApiService? apiService,
    StockPriceService? stockPriceService,
    TickerCacheService? cacheService,
  })  : _apiService = apiService ?? SecApiService(),
        _stockPriceService = stockPriceService ?? StockPriceService(),
        _cacheService = cacheService ?? TickerCacheService();

  List<SecCompany> get searchResults => List.unmodifiable(_searchResults);
  SecCompany? get selectedCompany => _selectedCompany;
  SecFinancialData? get financialData => _financialData;
  bool get isLoading => _isLoading;
  bool get isCacheLoading => _isCacheLoading;
  String? get error => _error;
  String? get stockPriceError => _stockPriceError;

  /// Initialize ticker cache. Call on app startup.
  Future<void> init() async {
    await _cacheService.init();
    if (!_cacheService.isCacheValid) {
      await refreshTickerCache();
    }
  }

  /// Refresh the local ticker cache from SEC.
  Future<void> refreshTickerCache() async {
    try {
      _isCacheLoading = true;
      _error = null;
      notifyListeners();

      final tickers = await _apiService.fetchAllTickers();
      await _cacheService.updateCache(tickers);
    } catch (e) {
      _error = 'Failed to fetch tickers: $e';
    } finally {
      _isCacheLoading = false;
      notifyListeners();
    }
  }

  /// Search companies using the local cache.
  void searchCompanies(String query) {
    _searchResults = _cacheService.search(query);
    notifyListeners();
  }

  /// Select a company and fetch its financial data from SEC + stock price.
  Future<void> selectCompany(SecCompany company) async {
    try {
      _selectedCompany = company;
      _financialData = null;
      _isLoading = true;
      _error = null;
      _stockPriceError = null;
      notifyListeners();

      // Fetch SEC data and stock price in parallel
      final results = await Future.wait([
        _apiService.getFinancialData(company),
        _stockPriceService.getPrice(company.ticker),
      ]);

      _financialData = results[0] as SecFinancialData?;
      final priceResult =
          results[1] as ({double? price, String? marketState});

      if (_financialData == null) {
        _error = 'No financial data available for ${company.ticker}';
      } else if (priceResult.price != null) {
        _financialData = _financialData!.copyWithPrice(
          currentStockPrice: priceResult.price,
          stockPriceAsOf: DateTime.now(),
        );
      } else {
        _stockPriceError = 'Could not fetch stock price for ${company.ticker}';
      }
    } catch (e) {
      _error = 'Failed to fetch data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear the current selection and results.
  void clearSelection() {
    _selectedCompany = null;
    _financialData = null;
    _searchResults = [];
    _error = null;
    _stockPriceError = null;
    notifyListeners();
  }
}
