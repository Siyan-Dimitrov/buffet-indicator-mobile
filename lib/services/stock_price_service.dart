import 'package:dio/dio.dart';

/// Fetches current stock price from Yahoo Finance API.
class StockPriceService {
  static const String _baseUrl = 'https://query1.finance.yahoo.com';

  final Dio _dio;

  StockPriceService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            }));

  /// Fetch current stock price for a ticker.
  ///
  /// Returns price and market state (e.g. "REGULAR", "PRE", "POST", "CLOSED").
  Future<({double? price, String? marketState})> getPrice(
      String ticker) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/v8/finance/chart/$ticker',
        queryParameters: {
          'range': '1d',
          'interval': '1d',
        },
      );

      final data = response.data as Map<String, dynamic>;
      final result =
          (data['chart']?['result'] as List<dynamic>?)?.firstOrNull;
      if (result == null) {
        return (price: null, marketState: null);
      }

      final meta = result['meta'] as Map<String, dynamic>?;
      final price = (meta?['regularMarketPrice'] as num?)?.toDouble();
      final marketState = meta?['marketState'] as String?;

      return (price: price, marketState: marketState);
    } on DioException {
      return (price: null, marketState: null);
    }
  }
}
