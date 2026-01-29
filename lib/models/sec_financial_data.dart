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
  final double? operatingCashFlow;
  final double? capex;
  final double? depreciation;

  // Point-in-time metrics (latest value from 10-K or 10-Q)
  final double? totalDebt;
  final double? cashAndEquivalents;
  final double? sharesDiluted;

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
    this.operatingCashFlow,
    this.capex,
    this.depreciation,
    this.totalDebt,
    this.cashAndEquivalents,
    this.sharesDiluted,
    required this.periodDescription,
    this.periodEndDate,
    this.isTtm = false,
  });

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

  @override
  List<Object?> get props => [
        cik,
        ticker,
        companyName,
        revenue,
        operatingIncome,
        netIncome,
        operatingCashFlow,
        capex,
        depreciation,
        totalDebt,
        cashAndEquivalents,
        sharesDiluted,
        periodDescription,
        periodEndDate,
        isTtm,
      ];
}
