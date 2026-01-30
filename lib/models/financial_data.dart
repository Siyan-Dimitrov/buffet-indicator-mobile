import 'dart:convert';

import 'package:equatable/equatable.dart';

/// Input data for quarterly financial analysis
class FinancialInputs extends Equatable {
  final String companyName;
  final String ticker;
  final double revenue;
  final double operatingIncome;
  final double netIncome;
  final double freeCashFlow;
  final double marketCap;
  final double totalDebt;
  final double cashAndEquivalents;
  final double ebitda;

  const FinancialInputs({
    required this.companyName,
    required this.ticker,
    required this.revenue,
    required this.operatingIncome,
    required this.netIncome,
    required this.freeCashFlow,
    required this.marketCap,
    required this.totalDebt,
    required this.cashAndEquivalents,
    required this.ebitda,
  });

  /// Calculate net debt
  double get netDebt => totalDebt - cashAndEquivalents;

  @override
  List<Object?> get props => [
        companyName,
        ticker,
        revenue,
        operatingIncome,
        netIncome,
        freeCashFlow,
        marketCap,
        totalDebt,
        cashAndEquivalents,
        ebitda,
      ];

  Map<String, dynamic> toJson() => {
        'companyName': companyName,
        'ticker': ticker,
        'revenue': revenue,
        'operatingIncome': operatingIncome,
        'netIncome': netIncome,
        'freeCashFlow': freeCashFlow,
        'marketCap': marketCap,
        'totalDebt': totalDebt,
        'cashAndEquivalents': cashAndEquivalents,
        'ebitda': ebitda,
      };

  factory FinancialInputs.fromJson(Map<String, dynamic> json) {
    return FinancialInputs(
      companyName: json['companyName'] as String,
      ticker: json['ticker'] as String,
      revenue: (json['revenue'] as num).toDouble(),
      operatingIncome: (json['operatingIncome'] as num).toDouble(),
      netIncome: (json['netIncome'] as num).toDouble(),
      freeCashFlow: (json['freeCashFlow'] as num).toDouble(),
      marketCap: (json['marketCap'] as num).toDouble(),
      totalDebt: (json['totalDebt'] as num).toDouble(),
      cashAndEquivalents: (json['cashAndEquivalents'] as num).toDouble(),
      ebitda: (json['ebitda'] as num).toDouble(),
    );
  }
}

/// Derived financial metrics calculated from inputs
class DerivedMetrics extends Equatable {
  final double fcfYield;
  final double operatingMargin;
  final double netMargin;
  final double leverage; // Net Debt / EBITDA

  const DerivedMetrics({
    required this.fcfYield,
    required this.operatingMargin,
    required this.netMargin,
    required this.leverage,
  });

  factory DerivedMetrics.fromInputs(FinancialInputs inputs) {
    return DerivedMetrics(
      fcfYield: inputs.marketCap > 0
          ? (inputs.freeCashFlow / inputs.marketCap) * 100
          : 0,
      operatingMargin: inputs.revenue > 0
          ? (inputs.operatingIncome / inputs.revenue) * 100
          : 0,
      netMargin:
          inputs.revenue > 0 ? (inputs.netIncome / inputs.revenue) * 100 : 0,
      leverage: inputs.ebitda > 0 ? inputs.netDebt / inputs.ebitda : 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'fcfYield': fcfYield,
        'operatingMargin': operatingMargin,
        'netMargin': netMargin,
        'leverage': leverage,
      };

  factory DerivedMetrics.fromJson(Map<String, dynamic> json) {
    return DerivedMetrics(
      fcfYield: (json['fcfYield'] as num).toDouble(),
      operatingMargin: (json['operatingMargin'] as num).toDouble(),
      netMargin: (json['netMargin'] as num).toDouble(),
      leverage: (json['leverage'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [fcfYield, operatingMargin, netMargin, leverage];
}

/// Investment profile with threshold rules
class InvestorProfile extends Equatable {
  final String name;
  final String description;
  final double minFcfYield;
  final double minOperatingMargin;
  final double minNetMargin;
  final double maxLeverage;

  const InvestorProfile({
    required this.name,
    required this.description,
    required this.minFcfYield,
    required this.minOperatingMargin,
    required this.minNetMargin,
    required this.maxLeverage,
  });

  @override
  List<Object?> get props => [
        name,
        minFcfYield,
        minOperatingMargin,
        minNetMargin,
        maxLeverage,
      ];

  factory InvestorProfile.fromName(String name) {
    return all.firstWhere(
      (p) => p.name == name,
      orElse: () => buffett,
    );
  }

  // Predefined investor profiles
  static const buffett = InvestorProfile(
    name: 'Warren Buffett',
    description: 'Focus on quality businesses with strong moats',
    minFcfYield: 5.0,
    minOperatingMargin: 15.0,
    minNetMargin: 10.0,
    maxLeverage: 2.0,
  );

  static const munger = InvestorProfile(
    name: 'Charlie Munger',
    description: 'Quality at a fair price',
    minFcfYield: 4.0,
    minOperatingMargin: 20.0,
    minNetMargin: 12.0,
    maxLeverage: 1.5,
  );

  static const graham = InvestorProfile(
    name: 'Benjamin Graham',
    description: 'Deep value with margin of safety',
    minFcfYield: 8.0,
    minOperatingMargin: 10.0,
    minNetMargin: 5.0,
    maxLeverage: 1.0,
  );

  static const burry = InvestorProfile(
    name: 'Michael Burry',
    description: 'Contrarian deep value',
    minFcfYield: 10.0,
    minOperatingMargin: 8.0,
    minNetMargin: 5.0,
    maxLeverage: 2.5,
  );

  static const greenblatt = InvestorProfile(
    name: 'Joel Greenblatt',
    description: 'Magic formula - high returns, low price',
    minFcfYield: 6.0,
    minOperatingMargin: 25.0,
    minNetMargin: 15.0,
    maxLeverage: 2.0,
  );

  static const lynch = InvestorProfile(
    name: 'Peter Lynch',
    description: 'Growth at a reasonable price (GARP)',
    minFcfYield: 3.0,
    minOperatingMargin: 12.0,
    minNetMargin: 8.0,
    maxLeverage: 2.5,
  );

  static List<InvestorProfile> get all => [
        buffett,
        munger,
        graham,
        burry,
        greenblatt,
        lynch,
      ];
}

/// Analysis result with grade and prescriptions
class AnalysisResult extends Equatable {
  final FinancialInputs inputs;
  final DerivedMetrics metrics;
  final InvestorProfile profile;
  final String grade;
  final int score;
  final List<CriterionResult> criteria;
  final List<String> prescriptions;
  final DateTime analyzedAt;

  const AnalysisResult({
    required this.inputs,
    required this.metrics,
    required this.profile,
    required this.grade,
    required this.score,
    required this.criteria,
    required this.prescriptions,
    required this.analyzedAt,
  });

  Map<String, dynamic> toJson() => {
        'inputs': inputs.toJson(),
        'metrics': metrics.toJson(),
        'profileName': profile.name,
        'grade': grade,
        'score': score,
        'criteria': criteria.map((c) => c.toJson()).toList(),
        'prescriptions': prescriptions,
        'analyzedAt': analyzedAt.toIso8601String(),
      };

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      inputs: FinancialInputs.fromJson(json['inputs'] as Map<String, dynamic>),
      metrics:
          DerivedMetrics.fromJson(json['metrics'] as Map<String, dynamic>),
      profile: InvestorProfile.fromName(json['profileName'] as String),
      grade: json['grade'] as String,
      score: json['score'] as int,
      criteria: (json['criteria'] as List)
          .map((c) => CriterionResult.fromJson(c as Map<String, dynamic>))
          .toList(),
      prescriptions: (json['prescriptions'] as List).cast<String>(),
      analyzedAt: DateTime.parse(json['analyzedAt'] as String),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory AnalysisResult.fromJsonString(String jsonString) {
    return AnalysisResult.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>);
  }

  @override
  List<Object?> get props => [
        inputs,
        metrics,
        profile,
        grade,
        score,
        criteria,
        prescriptions,
        analyzedAt,
      ];
}

/// Result for a single criterion
class CriterionResult extends Equatable {
  final String name;
  final double actualValue;
  final double threshold;
  final bool passed;
  final String unit;
  final bool isMaximum; // true if threshold is a maximum (like leverage)

  const CriterionResult({
    required this.name,
    required this.actualValue,
    required this.threshold,
    required this.passed,
    required this.unit,
    this.isMaximum = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'actualValue': actualValue,
        'threshold': threshold,
        'passed': passed,
        'unit': unit,
        'isMaximum': isMaximum,
      };

  factory CriterionResult.fromJson(Map<String, dynamic> json) {
    return CriterionResult(
      name: json['name'] as String,
      actualValue: (json['actualValue'] as num).toDouble(),
      threshold: (json['threshold'] as num).toDouble(),
      passed: json['passed'] as bool,
      unit: json['unit'] as String,
      isMaximum: json['isMaximum'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        name,
        actualValue,
        threshold,
        passed,
        unit,
        isMaximum,
      ];
}
