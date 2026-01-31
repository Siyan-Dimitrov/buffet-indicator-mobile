import '../models/financial_data.dart';

/// Service for performing financial analysis calculations
class AnalysisService {
  /// Analyze financial data against all investor profiles
  List<AnalysisResult> analyzeAll(FinancialInputs inputs) {
    return InvestorProfile.all
        .map((profile) => analyze(inputs, profile))
        .toList();
  }

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
    final criteria = <CriterionResult>[
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

    // P/E Ratio
    if (profile.maxPeRatio != null && metrics.peRatio != null) {
      criteria.add(CriterionResult(
        name: 'P/E Ratio',
        actualValue: metrics.peRatio!,
        threshold: profile.maxPeRatio!,
        passed: metrics.peRatio! <= profile.maxPeRatio!,
        unit: 'x',
        isMaximum: true,
      ));
    }

    // EV/EBITDA
    if (profile.maxEvToEbitda != null && metrics.evToEbitda != null) {
      criteria.add(CriterionResult(
        name: 'EV/EBITDA',
        actualValue: metrics.evToEbitda!,
        threshold: profile.maxEvToEbitda!,
        passed: metrics.evToEbitda! <= profile.maxEvToEbitda!,
        unit: 'x',
        isMaximum: true,
      ));
    }

    // P/FCF
    if (profile.maxPToFcf != null && metrics.pToFcf != null) {
      criteria.add(CriterionResult(
        name: 'P/FCF',
        actualValue: metrics.pToFcf!,
        threshold: profile.maxPToFcf!,
        passed: metrics.pToFcf! <= profile.maxPToFcf!,
        unit: 'x',
        isMaximum: true,
      ));
    }

    // P/B Ratio
    if (profile.maxPbRatio != null && metrics.pbRatio != null) {
      criteria.add(CriterionResult(
        name: 'P/B Ratio',
        actualValue: metrics.pbRatio!,
        threshold: profile.maxPbRatio!,
        passed: metrics.pbRatio! <= profile.maxPbRatio!,
        unit: 'x',
        isMaximum: true,
      ));
    }

    // ROIC
    if (profile.minRoic != null && metrics.roic != null) {
      criteria.add(CriterionResult(
        name: 'ROIC',
        actualValue: metrics.roic!,
        threshold: profile.minRoic!,
        passed: metrics.roic! >= profile.minRoic!,
        unit: '%',
      ));
    }

    // ROE
    if (profile.minRoe != null && metrics.roe != null) {
      criteria.add(CriterionResult(
        name: 'ROE',
        actualValue: metrics.roe!,
        threshold: profile.minRoe!,
        passed: metrics.roe! >= profile.minRoe!,
        unit: '%',
      ));
    }

    // FCF/Net Income
    if (profile.minFcfToNetIncome != null && metrics.fcfToNetIncome != null) {
      criteria.add(CriterionResult(
        name: 'FCF/Net Income',
        actualValue: metrics.fcfToNetIncome!,
        threshold: profile.minFcfToNetIncome!,
        passed: metrics.fcfToNetIncome! >= profile.minFcfToNetIncome!,
        unit: '%',
      ));
    }

    // PEG Ratio
    if (profile.maxPegRatio != null && metrics.pegRatio != null) {
      criteria.add(CriterionResult(
        name: 'PEG Ratio',
        actualValue: metrics.pegRatio!,
        threshold: profile.maxPegRatio!,
        passed: metrics.pegRatio! <= profile.maxPegRatio!,
        unit: 'x',
        isMaximum: true,
      ));
    }

    return criteria;
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

    // P/E Ratio prescription
    if (profile.maxPeRatio != null &&
        metrics.peRatio != null &&
        metrics.peRatio! > profile.maxPeRatio!) {
      final requiredMarketCap = profile.maxPeRatio! * inputs.netIncome;
      final marketCapDrop = inputs.marketCap - requiredMarketCap;
      if (marketCapDrop > 0) {
        prescriptions.add(
          'P/E Ratio: Need ${(marketCapDrop / inputs.marketCap * 100).toStringAsFixed(1)}% '
          'market cap drop (\$${_formatNumber(marketCapDrop)}) to reach ${profile.maxPeRatio!.toStringAsFixed(0)}x target',
        );
      }
    }

    // EV/EBITDA prescription
    if (profile.maxEvToEbitda != null &&
        metrics.evToEbitda != null &&
        metrics.evToEbitda! > profile.maxEvToEbitda!) {
      final requiredEv = profile.maxEvToEbitda! * inputs.ebitda;
      final currentEv = inputs.marketCap + inputs.netDebt;
      final evDrop = currentEv - requiredEv;
      if (evDrop > 0) {
        prescriptions.add(
          'EV/EBITDA: Need \$${_formatNumber(evDrop)} enterprise value reduction '
          'to reach ${profile.maxEvToEbitda!.toStringAsFixed(0)}x target',
        );
      }
    }

    // P/FCF prescription
    if (profile.maxPToFcf != null &&
        metrics.pToFcf != null &&
        metrics.pToFcf! > profile.maxPToFcf!) {
      final requiredMarketCap = profile.maxPToFcf! * inputs.freeCashFlow;
      final marketCapDrop = inputs.marketCap - requiredMarketCap;
      if (marketCapDrop > 0) {
        prescriptions.add(
          'P/FCF: Need ${(marketCapDrop / inputs.marketCap * 100).toStringAsFixed(1)}% '
          'market cap drop (\$${_formatNumber(marketCapDrop)}) to reach ${profile.maxPToFcf!.toStringAsFixed(0)}x target',
        );
      }
    }

    // P/B Ratio prescription
    if (profile.maxPbRatio != null &&
        metrics.pbRatio != null &&
        metrics.pbRatio! > profile.maxPbRatio!) {
      final requiredMarketCap = profile.maxPbRatio! * inputs.totalEquity;
      final marketCapDrop = inputs.marketCap - requiredMarketCap;
      if (marketCapDrop > 0) {
        prescriptions.add(
          'P/B Ratio: Need ${(marketCapDrop / inputs.marketCap * 100).toStringAsFixed(1)}% '
          'market cap drop (\$${_formatNumber(marketCapDrop)}) to reach ${profile.maxPbRatio!.toStringAsFixed(1)}x target',
        );
      }
    }

    // ROIC prescription
    if (profile.minRoic != null &&
        metrics.roic != null &&
        metrics.roic! < profile.minRoic!) {
      final investedCapital =
          inputs.totalEquity + inputs.totalDebt - inputs.cashAndEquivalents;
      final requiredNopat = profile.minRoic! / 100 * investedCapital;
      final requiredOpIncome = requiredNopat / 0.75;
      final opIncomeGap = requiredOpIncome - inputs.operatingIncome;
      if (opIncomeGap > 0) {
        prescriptions.add(
          'ROIC: Need +\$${_formatNumber(opIncomeGap)} operating income '
          'to reach ${profile.minRoic!.toStringAsFixed(0)}% target',
        );
      }
    }

    // ROE prescription
    if (profile.minRoe != null &&
        metrics.roe != null &&
        metrics.roe! < profile.minRoe!) {
      final requiredNetIncome =
          profile.minRoe! / 100 * inputs.totalEquity;
      final netIncomeGap = requiredNetIncome - inputs.netIncome;
      if (netIncomeGap > 0) {
        prescriptions.add(
          'ROE: Need +\$${_formatNumber(netIncomeGap)} net income '
          'to reach ${profile.minRoe!.toStringAsFixed(0)}% target',
        );
      }
    }

    // FCF/Net Income prescription
    if (profile.minFcfToNetIncome != null &&
        metrics.fcfToNetIncome != null &&
        metrics.fcfToNetIncome! < profile.minFcfToNetIncome!) {
      final requiredFcf =
          profile.minFcfToNetIncome! / 100 * inputs.netIncome;
      final fcfGap = requiredFcf - inputs.freeCashFlow;
      if (fcfGap > 0) {
        prescriptions.add(
          'FCF/Net Income: Need +\$${_formatNumber(fcfGap)} free cash flow '
          'to reach ${profile.minFcfToNetIncome!.toStringAsFixed(0)}% conversion target',
        );
      }
    }

    // PEG Ratio prescription
    if (profile.maxPegRatio != null &&
        metrics.pegRatio != null &&
        metrics.pegRatio! > profile.maxPegRatio!) {
      prescriptions.add(
        'PEG Ratio: Current ${metrics.pegRatio!.toStringAsFixed(2)}x exceeds '
        '${profile.maxPegRatio!.toStringAsFixed(1)}x target — '
        'need higher earnings growth or lower P/E',
      );
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
