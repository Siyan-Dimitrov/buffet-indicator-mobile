import 'package:equatable/equatable.dart';

/// Financial data parsed from SEC XBRL filings with TTM support.
class SecFinancialData extends Equatable {
  final String cik;
  final String ticker;
  final String companyName;

  // Flow metrics (TTM-calculated when newer 10-Q data is available)
  final double? revenue;
  final double? operatingIncome;
  final double? netIncome;
  final double? priorYearNetIncome;
  final double? operatingCashFlow;
  final double? capex;
  final double? depreciation;

  // Point-in-time metrics (latest value from 10-K or 10-Q)
  final double? totalDebt;
  final double? cashAndEquivalents;
  final double? totalEquity;
  final double? sharesDiluted;

  // Stock price (from Yahoo Finance)
  final double? currentStockPrice;
  final DateTime? stockPriceAsOf;

  // TTM metadata
  final String periodDescription;
  final DateTime? periodEndDate;
  final bool isTtm;

  const SecFinancialData({
    required this.cik,
    required this.ticker,
    required this.companyName,
    this.revenue,
    this.operatingIncome,
    this.netIncome,
    this.priorYearNetIncome,
    this.operatingCashFlow,
    this.capex,
    this.depreciation,
    this.totalDebt,
    this.cashAndEquivalents,
    this.totalEquity,
    this.sharesDiluted,
    this.currentStockPrice,
    this.stockPriceAsOf,
    required this.periodDescription,
    this.periodEndDate,
    this.isTtm = false,
  });

  /// Create a copy with updated stock price fields.
  SecFinancialData copyWithPrice({
    double? currentStockPrice,
    DateTime? stockPriceAsOf,
  }) {
    return SecFinancialData(
      cik: cik,
      ticker: ticker,
      companyName: companyName,
      revenue: revenue,
      operatingIncome: operatingIncome,
      netIncome: netIncome,
      priorYearNetIncome: priorYearNetIncome,
      operatingCashFlow: operatingCashFlow,
      capex: capex,
      depreciation: depreciation,
      totalDebt: totalDebt,
      cashAndEquivalents: cashAndEquivalents,
      totalEquity: totalEquity,
      sharesDiluted: sharesDiluted,
      currentStockPrice: currentStockPrice ?? this.currentStockPrice,
      stockPriceAsOf: stockPriceAsOf ?? this.stockPriceAsOf,
      periodDescription: periodDescription,
      periodEndDate: periodEndDate,
      isTtm: isTtm,
    );
  }

  /// Free Cash Flow = Operating Cash Flow - |CapEx|
  double? get freeCashFlow {
    if (operatingCashFlow != null && capex != null) {
      return operatingCashFlow! - capex!.abs();
    }
    return null;
  }

  /// EBITDA = Operating Income + Depreciation (falls back to operating income alone)
  double? get calculatedEbitda {
    if (operatingIncome != null && depreciation != null) {
      return operatingIncome! + depreciation!;
    }
    return operatingIncome;
  }

  /// Year-over-year earnings growth rate (%).
  /// Returns null if prior-year net income is unavailable or non-positive.
  double? get earningsGrowthRate {
    if (netIncome != null &&
        priorYearNetIncome != null &&
        priorYearNetIncome! > 0) {
      return ((netIncome! - priorYearNetIncome!) / priorYearNetIncome!) * 100;
    }
    return null;
  }

  @override
  List<Object?> get props => [
        cik,
        ticker,
        companyName,
        revenue,
        operatingIncome,
        netIncome,
        priorYearNetIncome,
        operatingCashFlow,
        capex,
        depreciation,
        totalDebt,
        cashAndEquivalents,
        totalEquity,
        sharesDiluted,
        currentStockPrice,
        stockPriceAsOf,
        periodDescription,
        periodEndDate,
        isTtm,
      ];
}
