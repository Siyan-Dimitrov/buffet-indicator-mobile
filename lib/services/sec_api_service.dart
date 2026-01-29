import 'package:dio/dio.dart';

import '../models/sec_company.dart';
import '../models/sec_financial_data.dart';
import '../models/xbrl_filing_entry.dart';

/// SEC EDGAR API client with TTM (Trailing Twelve Months) calculation.
class SecApiService {
  static const String _baseUrl = 'https://data.sec.gov';
  static const String _tickersUrl =
      'https://www.sec.gov/files/company_tickers.json';
  static const Duration _rateLimitDelay = Duration(milliseconds: 150);

  /// XBRL tags for flow metrics (income statement, cash flow).
  /// These are summed over time and need TTM calculation.
  static const Map<String, List<String>> flowTags = {
    'revenue': [
      'RevenueFromContractWithCustomerExcludingAssessedTax',
      'RevenueFromContractWithCustomerIncludingAssessedTax',
      'Revenues',
      'SalesRevenueNet',
      'SalesRevenueGoodsNet',
      'TotalRevenuesAndOtherIncome',
    ],
    'operating_income': [
      'OperatingIncomeLoss',
      'IncomeLossFromOperations',
    ],
    'net_income': [
      'NetIncomeLoss',
      'NetIncomeLossAvailableToCommonStockholdersBasic',
    ],
    'operating_cash_flow': [
      'NetCashProvidedByUsedInOperatingActivities',
      'NetCashProvidedByUsedInOperatingActivitiesContinuingOperations',
    ],
    'capex': [
      'PaymentsToAcquirePropertyPlantAndEquipment',
      'PaymentsToAcquireProductiveAssets',
    ],
    'depreciation': [
      'DepreciationDepletionAndAmortization',
      'DepreciationAndAmortization',
      'Depreciation',
    ],
  };

  /// XBRL tags for point-in-time metrics (balance sheet).
  /// These are snapshots — just use the latest value.
  static const Map<String, List<String>> instantTags = {
    'long_term_debt': [
      'LongTermDebt',
      'LongTermDebtAndCapitalLeaseObligations',
    ],
    'short_term_debt': [
      'ShortTermBorrowings',
      'DebtCurrent',
    ],
    'cash': [
      'CashAndCashEquivalentsAtCarryingValue',
      'CashCashEquivalentsAndShortTermInvestments',
    ],
  };

  /// Shares can use either "shares" or "pure" unit types.
  static const List<String> sharesTags = [
    'WeightedAverageNumberOfDilutedSharesOutstanding',
    'CommonStockSharesOutstanding',
  ];

  final Dio _dio;
  DateTime? _lastRequestTime;

  SecApiService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(headers: {
              'User-Agent': 'BuffetIndicator/1.0 (buffetindicator@example.com)',
              'Accept': 'application/json',
            }));

  /// Enforce SEC rate limit (max 10 requests/second).
  Future<void> _rateLimit() async {
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < _rateLimitDelay) {
        await Future.delayed(_rateLimitDelay - elapsed);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  /// Fetch all company tickers from SEC.
  Future<List<SecCompany>> fetchAllTickers() async {
    await _rateLimit();
    final response = await _dio.get(_tickersUrl);
    final Map<String, dynamic> data = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : {};

    return data.values
        .map((json) => SecCompany.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get raw company facts (XBRL data) for a CIK.
  Future<Map<String, dynamic>?> getCompanyFacts(String cik) async {
    await _rateLimit();
    final paddedCik = cik.padLeft(10, '0');
    try {
      final response =
          await _dio.get('$_baseUrl/api/xbrl/companyfacts/CIK$paddedCik.json');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Get parsed financial data with TTM calculation for a company.
  Future<SecFinancialData?> getFinancialData(SecCompany company) async {
    final facts = await getCompanyFacts(company.cik);
    if (facts == null) return null;

    // Flow metrics with TTM
    final revenue = _extractTtmValue(facts, flowTags['revenue']!);
    final opIncome = _extractTtmValue(facts, flowTags['operating_income']!);
    final netIncome = _extractTtmValue(facts, flowTags['net_income']!);
    final opCashFlow =
        _extractTtmValue(facts, flowTags['operating_cash_flow']!);
    final capex = _extractTtmValue(facts, flowTags['capex']!);
    final depreciation = _extractTtmValue(facts, flowTags['depreciation']!);

    // Point-in-time metrics
    final longTermDebt =
        _extractInstantValue(facts, instantTags['long_term_debt']!);
    final shortTermDebt =
        _extractInstantValue(facts, instantTags['short_term_debt']!);
    final totalDebt = addNullable(longTermDebt, shortTermDebt);
    final cash = _extractInstantValue(facts, instantTags['cash']!);

    // Shares (uses "shares" unit)
    final shares = _extractSharesValue(facts, sharesTags);

    final periodDesc = revenue.description;
    final isTtm = periodDesc.startsWith('TTM');

    // Parse period end date from the most recent entry description
    DateTime? periodEndDate;
    final revenueEntries =
        _parseEntries(facts, flowTags['revenue']!, unitType: 'USD');
    if (revenueEntries.isNotEmpty) {
      revenueEntries.sort((a, b) => b.end.compareTo(a.end));
      periodEndDate = DateTime.tryParse(revenueEntries.first.end);
    }

    return SecFinancialData(
      cik: company.cik,
      ticker: company.ticker,
      companyName: company.name,
      revenue: revenue.value,
      operatingIncome: opIncome.value,
      netIncome: netIncome.value,
      operatingCashFlow: opCashFlow.value,
      capex: capex.value?.abs(),
      depreciation: depreciation.value,
      totalDebt: totalDebt,
      cashAndEquivalents: cash,
      sharesDiluted: shares,
      periodDescription: periodDesc,
      periodEndDate: periodEndDate,
      isTtm: isTtm,
    );
  }

  /// Extract TTM value for a flow metric.
  ///
  /// Algorithm:
  /// 1. Find the most recent 10-K annual entry (baseline, covers 12 months)
  /// 2. Find any 10-Q entries newer than the 10-K
  /// 3. If none: return the 10-K value
  /// 4. If newer 10-Q: TTM = annual + current_YTD - prior_year_same_period_YTD
  ({double? value, String description}) _extractTtmValue(
    Map<String, dynamic> facts,
    List<String> tags,
  ) {
    final entries = _parseEntries(facts, tags, unitType: 'USD');
    if (entries.isEmpty) return (value: null, description: 'No data');

    // Find the most recent 10-K annual entry (has start date, ~365 day period)
    final annualEntries = entries
        .where((e) => e.isAnnual && !e.isInstant)
        .toList()
      ..sort((a, b) => b.end.compareTo(a.end));

    if (annualEntries.isEmpty) {
      return (value: null, description: 'No annual filing found');
    }

    final latestAnnual = annualEntries.first;
    final annualEndDate = DateTime.parse(latestAnnual.end);

    // Find 10-Q entries with end dates after the annual
    final newerQuarterly = entries
        .where((e) =>
            e.isQuarterly &&
            !e.isInstant &&
            DateTime.parse(e.end).isAfter(annualEndDate))
        .toList()
      ..sort((a, b) => b.end.compareTo(a.end));

    // No newer quarterly data — return the annual value
    if (newerQuarterly.isEmpty) {
      return (
        value: latestAnnual.val,
        description: 'FY ${latestAnnual.fy}',
      );
    }

    // TTM calculation using YTD approach
    final mostRecentQ = newerQuarterly.first;
    final currentFp = mostRecentQ.fp;

    double? currentYtdValue;

    if (mostRecentQ.isYtdCumulative) {
      // Already a YTD cumulative figure — use directly
      currentYtdValue = mostRecentQ.val;
    } else if (mostRecentQ.isStandaloneQuarter) {
      // Sum all standalone quarters from the current fiscal year
      // that are newer than the annual
      currentYtdValue = newerQuarterly
          .where((e) => e.fy == mostRecentQ.fy && e.isStandaloneQuarter)
          .fold<double>(0, (sum, e) => sum + e.val);
    } else {
      // Ambiguous period — fall back to annual
      return (
        value: latestAnnual.val,
        description: 'FY ${latestAnnual.fy}',
      );
    }

    // Find the prior-year same-period YTD value
    final priorYearFy = latestAnnual.fy;
    final priorYearSamePeriod = entries
        .where((e) =>
            e.fp == currentFp &&
            e.fy == priorYearFy &&
            !e.isInstant &&
            !e.isAnnual)
        .toList()
      ..sort((a, b) => b.end.compareTo(a.end));

    if (priorYearSamePeriod.isEmpty) {
      // Cannot compute TTM — fall back to annual
      return (
        value: latestAnnual.val,
        description: 'FY ${latestAnnual.fy}',
      );
    }

    double priorYtdValue;
    final priorEntry = priorYearSamePeriod.first;

    if (priorEntry.isYtdCumulative) {
      priorYtdValue = priorEntry.val;
    } else if (priorEntry.isStandaloneQuarter) {
      // Sum standalone quarters for the same set of quarters in the prior year
      priorYtdValue = entries
          .where((e) =>
              e.fy == priorYearFy &&
              e.isStandaloneQuarter &&
              !e.isAnnual &&
              XbrlFilingEntry.quarterIndex(e.fp) <=
                  XbrlFilingEntry.quarterIndex(currentFp))
          .fold<double>(0, (sum, e) => sum + e.val);
    } else {
      return (
        value: latestAnnual.val,
        description: 'FY ${latestAnnual.fy}',
      );
    }

    final ttmValue = latestAnnual.val + currentYtdValue - priorYtdValue;
    return (
      value: ttmValue,
      description: 'TTM ending $currentFp ${mostRecentQ.fy}',
    );
  }

  /// Extract latest point-in-time value (balance sheet items).
  double? _extractInstantValue(
    Map<String, dynamic> facts,
    List<String> tags,
  ) {
    final entries = _parseEntries(facts, tags, unitType: 'USD');
    final instantEntries = entries.where((e) => e.isInstant).toList()
      ..sort((a, b) => b.end.compareTo(a.end));

    return instantEntries.isNotEmpty ? instantEntries.first.val : null;
  }

  /// Extract latest shares value (uses "shares" unit type).
  double? _extractSharesValue(
    Map<String, dynamic> facts,
    List<String> tags,
  ) {
    final entries = _parseEntries(facts, tags, unitType: 'shares');
    if (entries.isEmpty) {
      // Some companies report under "pure" unit
      final pureEntries = _parseEntries(facts, tags, unitType: 'pure');
      if (pureEntries.isNotEmpty) {
        pureEntries.sort((a, b) => b.end.compareTo(a.end));
        return pureEntries.first.val;
      }
      return null;
    }
    entries.sort((a, b) => b.end.compareTo(a.end));
    return entries.first.val;
  }

  /// Parse XBRL entries from the facts JSON for the given tags.
  /// Tries tags in priority order, returns entries from the first matching tag.
  List<XbrlFilingEntry> _parseEntries(
    Map<String, dynamic> facts,
    List<String> tags, {
    required String unitType,
  }) {
    final usGaap = facts['facts']?['us-gaap'] as Map<String, dynamic>?;
    if (usGaap == null) return [];

    for (final tag in tags) {
      final tagData = usGaap[tag] as Map<String, dynamic>?;
      if (tagData == null) continue;

      final units = tagData['units'] as Map<String, dynamic>?;
      final unitData = units?[unitType] as List<dynamic>?;
      if (unitData == null || unitData.isEmpty) continue;

      return unitData
          .where(
              (e) => e['form'] == '10-K' || e['form'] == '10-Q')
          .map((e) => XbrlFilingEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Add two nullable doubles, returning null only if both are null.
  static double? addNullable(double? a, double? b) {
    if (a == null && b == null) return null;
    return (a ?? 0) + (b ?? 0);
  }
}
