import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:buffet_indicator/models/sec_company.dart';
import 'package:buffet_indicator/models/sec_financial_data.dart';
import 'package:buffet_indicator/providers/sec_provider.dart';
import 'package:buffet_indicator/services/sec_api_service.dart';
import 'package:buffet_indicator/services/stock_price_service.dart';

class _ControlledSecApiService extends SecApiService {
  final Map<String, Completer<SecFinancialData?>> requests = {};

  @override
  Future<SecFinancialData?> getFinancialData(SecCompany company) {
    return (requests[company.ticker] ??= Completer<SecFinancialData?>()).future;
  }
}

class _NoPriceService extends StockPriceService {
  @override
  Future<({String? marketState, double? price})> getPrice(String ticker) async {
    return (price: null, marketState: null);
  }
}

SecFinancialData _dataFor(SecCompany company) {
  return SecFinancialData(
    cik: company.cik,
    ticker: company.ticker,
    companyName: company.name,
    periodDescription: 'FY 2025',
  );
}

void main() {
  const companyA = SecCompany(cik: '0001', ticker: 'AAA', name: 'Company A');
  const companyB = SecCompany(cik: '0002', ticker: 'BBB', name: 'Company B');

  test('a slower old request cannot replace the latest selected company',
      () async {
    final api = _ControlledSecApiService();
    final provider = SecProvider(
      apiService: api,
      stockPriceService: _NoPriceService(),
    );

    final first = provider.selectCompany(companyA);
    final second = provider.selectCompany(companyB);

    api.requests['BBB']!.complete(_dataFor(companyB));
    await second;
    expect(provider.financialData?.ticker, 'BBB');

    api.requests['AAA']!.complete(_dataFor(companyA));
    await first;
    expect(provider.financialData?.ticker, 'BBB');
  });

  test('clearing a selection prevents an in-flight response repopulating it',
      () async {
    final api = _ControlledSecApiService();
    final provider = SecProvider(
      apiService: api,
      stockPriceService: _NoPriceService(),
    );

    final request = provider.selectCompany(companyA);
    provider.clearSelection();
    api.requests['AAA']!.complete(_dataFor(companyA));
    await request;

    expect(provider.selectedCompany, isNull);
    expect(provider.financialData, isNull);
    expect(provider.isLoading, isFalse);
  });
}
