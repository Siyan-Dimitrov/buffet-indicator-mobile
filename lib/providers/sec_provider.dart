import 'package:flutter/foundation.dart';

import '../models/sec_company.dart';
import '../models/sec_financial_data.dart';
import '../services/sec_api_service.dart';
import '../services/stock_price_service.dart';
import '../services/ticker_cache_service.dart';
import '../utils/app_exceptions.dart';

/// State management for SEC EDGAR API features.
class SecProvider extends ChangeNotifier {
  final SecApiService _apiService;
  final StockPriceService _stockPriceService;
  final TickerCacheService _cacheService;

  List<SecCompany> _searchResults = [];
  SecCompany? _selectedCompany;
  SecCompany? _lastSelectedCompany;
  SecFinancialData? _financialData;
  bool _isLoading = false;
  bool _isCacheLoading = false;
  AppException? _error;
  AppException? _stockPriceError;
  bool _lastErrorFromCache = false;

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
  AppException? get error => _error;
  AppException? get stockPriceError => _stockPriceError;

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
      _error = AppException.fromGeneric(e, context: 'Failed to load ticker list');
      _lastErrorFromCache = true;
      debugPrint('refreshTickerCache error: $_error');
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
      _lastSelectedCompany = company;
      _financialData = null;
      _isLoading = true;
      _error = null;
      _stockPriceError = null;
      _lastErrorFromCache = false;
      notifyListeners();

      // Fetch SEC data and stock price in parallel
      late final SecFinancialData? secData;
      late final ({double? price, String? marketState}) priceResult;

      Object? secError;
      Object? priceError;

      await Future.wait([
        _apiService.getFinancialData(company).then((v) => secData = v).catchError((Object e) {
          secError = e;
          secData = null;
          return null;
        }),
        _stockPriceService.getPrice(company.ticker).then((v) => priceResult = v).catchError((Object e) {
          priceError = e;
          priceResult = (price: null, marketState: null);
          return priceResult;
        }),
      ]);

      // Handle SEC data error (critical)
      if (secError != null) {
        _error = AppException.fromGeneric(secError!, context: 'Failed to load financial data');
        debugPrint('SEC data fetch error: $_error');
        return;
      }

      // Handle stock price error (non-fatal)
      if (priceError != null) {
        _stockPriceError = AppException.fromGeneric(priceError!, context: 'Stock price unavailable');
        debugPrint('Stock price fetch error: $_stockPriceError');
      }

      _financialData = secData;

      if (_financialData == null) {
        _error = const AppException(
          type: AppErrorType.notFound,
          userMessage: 'No financial data available for this company.',
        );
      } else if (priceResult.price != null) {
        _financialData = _financialData!.copyWithPrice(
          currentStockPrice: priceResult.price,
          stockPriceAsOf: DateTime.now(),
        );
      } else if (_stockPriceError == null) {
        _stockPriceError = const AppException(
          type: AppErrorType.notFound,
          userMessage: 'Stock price not available for this ticker.',
        );
      }
    } on AppException catch (e) {
      _error = e;
      debugPrint('selectCompany error: $e');
    } catch (e) {
      _error = AppException.fromGeneric(e, context: 'Failed to fetch data');
      debugPrint('selectCompany unexpected error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Retry the last failed operation (cache refresh or company selection).
  Future<void> retry() async {
    if (_lastErrorFromCache) {
      await refreshTickerCache();
    } else if (_lastSelectedCompany != null) {
      await selectCompany(_lastSelectedCompany!);
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
