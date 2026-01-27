import 'package:flutter_test/flutter_test.dart';

import 'package:buffet_indicator/models/financial_data.dart';
import 'package:buffet_indicator/services/analysis_service.dart';

void main() {
  group('FinancialInputs', () {
    test('calculates net debt correctly', () {
      const inputs = FinancialInputs(
        companyName: 'Test Corp',
        ticker: 'TEST',
        revenue: 100000,
        operatingIncome: 15000,
        netIncome: 10000,
        freeCashFlow: 8000,
        marketCap: 200000,
        totalDebt: 50000,
        cashAndEquivalents: 20000,
        ebitda: 20000,
      );

      expect(inputs.netDebt, equals(30000));
    });
  });

  group('DerivedMetrics', () {
    test('calculates metrics correctly', () {
      const inputs = FinancialInputs(
        companyName: 'Test Corp',
        ticker: 'TEST',
        revenue: 100000,
        operatingIncome: 15000,
        netIncome: 10000,
        freeCashFlow: 10000,
        marketCap: 200000,
        totalDebt: 50000,
        cashAndEquivalents: 20000,
        ebitda: 20000,
      );

      final metrics = DerivedMetrics.fromInputs(inputs);

      expect(metrics.fcfYield, equals(5.0)); // 10000/200000 * 100
      expect(metrics.operatingMargin, equals(15.0)); // 15000/100000 * 100
      expect(metrics.netMargin, equals(10.0)); // 10000/100000 * 100
      expect(metrics.leverage, equals(1.5)); // 30000/20000
    });

    test('handles zero revenue', () {
      const inputs = FinancialInputs(
        companyName: 'Test Corp',
        ticker: 'TEST',
        revenue: 0,
        operatingIncome: 15000,
        netIncome: 10000,
        freeCashFlow: 10000,
        marketCap: 200000,
        totalDebt: 50000,
        cashAndEquivalents: 20000,
        ebitda: 20000,
      );

      final metrics = DerivedMetrics.fromInputs(inputs);

      expect(metrics.operatingMargin, equals(0));
      expect(metrics.netMargin, equals(0));
    });
  });

  group('AnalysisService', () {
    late AnalysisService service;

    setUp(() {
      service = AnalysisService();
    });

    test('grades A when all criteria pass', () {
      const inputs = FinancialInputs(
        companyName: 'Excellent Corp',
        ticker: 'EXCL',
        revenue: 100000,
        operatingIncome: 20000, // 20% margin
        netIncome: 12000, // 12% margin
        freeCashFlow: 12000, // 6% FCF yield
        marketCap: 200000,
        totalDebt: 30000,
        cashAndEquivalents: 20000, // Net debt = 10000
        ebitda: 25000, // Leverage = 0.4x
      );

      final result = service.analyze(inputs, InvestorProfile.buffett);

      expect(result.grade, equals('A'));
      expect(result.score, equals(100));
      expect(result.criteria.every((c) => c.passed), isTrue);
    });

    test('grades F when no criteria pass', () {
      const inputs = FinancialInputs(
        companyName: 'Poor Corp',
        ticker: 'POOR',
        revenue: 100000,
        operatingIncome: 5000, // 5% margin (below 15%)
        netIncome: 2000, // 2% margin (below 10%)
        freeCashFlow: 4000, // 2% FCF yield (below 5%)
        marketCap: 200000,
        totalDebt: 100000,
        cashAndEquivalents: 10000, // Net debt = 90000
        ebitda: 20000, // Leverage = 4.5x (above 2x)
      );

      final result = service.analyze(inputs, InvestorProfile.buffett);

      expect(result.grade, equals('F'));
      expect(result.score, equals(0));
      expect(result.criteria.every((c) => !c.passed), isTrue);
    });

    test('generates prescriptions for failing criteria', () {
      const inputs = FinancialInputs(
        companyName: 'Mixed Corp',
        ticker: 'MIX',
        revenue: 100000,
        operatingIncome: 10000, // 10% margin (below 15%)
        netIncome: 8000, // 8% margin (below 10%)
        freeCashFlow: 6000, // 3% FCF yield (below 5%)
        marketCap: 200000,
        totalDebt: 50000,
        cashAndEquivalents: 10000, // Net debt = 40000
        ebitda: 15000, // Leverage = 2.67x (above 2x)
      );

      final result = service.analyze(inputs, InvestorProfile.buffett);

      expect(result.prescriptions.isNotEmpty, isTrue);
      expect(
        result.prescriptions.any((p) => p.contains('FCF Yield')),
        isTrue,
      );
      expect(
        result.prescriptions.any((p) => p.contains('Operating Margin')),
        isTrue,
      );
    });
  });

  group('InvestorProfile', () {
    test('has all expected profiles', () {
      expect(InvestorProfile.all.length, equals(6));
      expect(
        InvestorProfile.all.map((p) => p.name),
        containsAll([
          'Warren Buffett',
          'Charlie Munger',
          'Benjamin Graham',
          'Michael Burry',
          'Joel Greenblatt',
          'Peter Lynch',
        ]),
      );
    });
  });
}
