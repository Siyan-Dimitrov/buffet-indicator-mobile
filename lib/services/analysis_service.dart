import '../models/financial_data.dart';

/// Service for performing financial analysis calculations
class AnalysisService {
  /// Analyze financial data against an investor profile
  AnalysisResult analyze(FinancialInputs inputs, InvestorProfile profile) {
    final metrics = DerivedMetrics.fromInputs(inputs);
    final criteria = _evaluateCriteria(metrics, profile);
    final score = _calculateScore(criteria);
    final grade = _calculateGrade(score);
    final prescriptions = _generatePrescriptions(inputs, metrics, profile);

    return AnalysisResult(
      inputs: inputs,
      metrics: metrics,
      profile: profile,
      grade: grade,
      score: score,
      criteria: criteria,
      prescriptions: prescriptions,
      analyzedAt: DateTime.now(),
    );
  }

  List<CriterionResult> _evaluateCriteria(
    DerivedMetrics metrics,
    InvestorProfile profile,
  ) {
    return [
      CriterionResult(
        name: 'FCF Yield',
        actualValue: metrics.fcfYield,
        threshold: profile.minFcfYield,
        passed: metrics.fcfYield >= profile.minFcfYield,
        unit: '%',
      ),
      CriterionResult(
        name: 'Operating Margin',
        actualValue: metrics.operatingMargin,
        threshold: profile.minOperatingMargin,
        passed: metrics.operatingMargin >= profile.minOperatingMargin,
        unit: '%',
      ),
      CriterionResult(
        name: 'Net Margin',
        actualValue: metrics.netMargin,
        threshold: profile.minNetMargin,
        passed: metrics.netMargin >= profile.minNetMargin,
        unit: '%',
      ),
      CriterionResult(
        name: 'Leverage',
        actualValue: metrics.leverage,
        threshold: profile.maxLeverage,
        passed: metrics.leverage <= profile.maxLeverage,
        unit: 'x',
        isMaximum: true,
      ),
    ];
  }

  int _calculateScore(List<CriterionResult> criteria) {
    final passedCount = criteria.where((c) => c.passed).length;
    return (passedCount / criteria.length * 100).round();
  }

  String _calculateGrade(int score) {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }

  List<String> _generatePrescriptions(
    FinancialInputs inputs,
    DerivedMetrics metrics,
    InvestorProfile profile,
  ) {
    final prescriptions = <String>[];

    // FCF Yield prescription
    if (metrics.fcfYield < profile.minFcfYield) {
      final targetFcfYield = profile.minFcfYield / 100;
      final requiredMarketCap = inputs.freeCashFlow / targetFcfYield;
      final marketCapDrop = inputs.marketCap - requiredMarketCap;
      final dropPercent = (marketCapDrop / inputs.marketCap * 100);

      if (marketCapDrop > 0) {
        prescriptions.add(
          'FCF Yield: Need ${dropPercent.toStringAsFixed(1)}% market cap drop '
          '(\$${_formatNumber(marketCapDrop)}) to reach ${profile.minFcfYield}% target',
        );
      }
    }

    // Operating Margin prescription
    if (metrics.operatingMargin < profile.minOperatingMargin) {
      final targetMargin = profile.minOperatingMargin / 100;
      final requiredOpIncome = inputs.revenue * targetMargin;
      final opIncomeGap = requiredOpIncome - inputs.operatingIncome;

      prescriptions.add(
        'Operating Margin: Need +\$${_formatNumber(opIncomeGap)} operating income '
        'to reach ${profile.minOperatingMargin}% target',
      );
    }

    // Net Margin prescription
    if (metrics.netMargin < profile.minNetMargin) {
      final targetMargin = profile.minNetMargin / 100;
      final requiredNetIncome = inputs.revenue * targetMargin;
      final netIncomeGap = requiredNetIncome - inputs.netIncome;

      prescriptions.add(
        'Net Margin: Need +\$${_formatNumber(netIncomeGap)} net income '
        'to reach ${profile.minNetMargin}% target',
      );
    }

    // Leverage prescription
    if (metrics.leverage > profile.maxLeverage) {
      final netDebt = inputs.netDebt;
      final requiredNetDebt = profile.maxLeverage * inputs.ebitda;
      final debtReduction = netDebt - requiredNetDebt;

      if (debtReduction > 0) {
        prescriptions.add(
          'Leverage: Need -\$${_formatNumber(debtReduction)} net debt reduction '
          'to reach ${profile.maxLeverage}x target',
        );
      }

      // Alternative: EBITDA increase needed
      if (inputs.ebitda > 0) {
        final requiredEbitda = netDebt / profile.maxLeverage;
        final ebitdaIncrease = requiredEbitda - inputs.ebitda;
        if (ebitdaIncrease > 0) {
          prescriptions.add(
            'Leverage (alt): Or need +\$${_formatNumber(ebitdaIncrease)} EBITDA increase '
            'to reach ${profile.maxLeverage}x target',
          );
        }
      }
    }

    return prescriptions;
  }

  String _formatNumber(double value) {
    final absValue = value.abs();
    if (absValue >= 1e12) {
      return '${(value / 1e12).toStringAsFixed(2)}T';
    } else if (absValue >= 1e9) {
      return '${(value / 1e9).toStringAsFixed(2)}B';
    } else if (absValue >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(2)}M';
    } else if (absValue >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(2)}K';
    }
    return value.toStringAsFixed(2);
  }
}
