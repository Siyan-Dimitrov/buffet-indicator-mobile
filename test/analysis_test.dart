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
        totalEquity: 80000,
      );

      expect(inputs.netDebt, equals(30000));
    });
  });

  group('DerivedMetrics', () {
    test('calculates base metrics correctly', () {
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
        totalEquity: 80000,
      );

      final metrics = DerivedMetrics.fromInputs(inputs);

      expect(metrics.fcfYield, equals(5.0)); // 10000/200000 * 100
      expect(metrics.operatingMargin, equals(15.0)); // 15000/100000 * 100
      expect(metrics.netMargin, equals(10.0)); // 10000/100000 * 100
      expect(metrics.leverage, equals(1.5)); // 30000/20000
    });

    test('calculates new valuation metrics correctly', () {
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
        totalEquity: 80000,
        earningsGrowthRate: 15.0,
      );

      final metrics = DerivedMetrics.fromInputs(inputs);

      // P/E = 200000 / 10000 = 20x
      expect(metrics.peRatio, equals(20.0));

      // EV/EBITDA = (200000 + 30000) / 20000 = 11.5x
      expect(metrics.evToEbitda, equals(11.5));

      // P/FCF = 200000 / 10000 = 20x
      expect(metrics.pToFcf, equals(20.0));

      // P/B = 200000 / 80000 = 2.5x
      expect(metrics.pbRatio, equals(2.5));

      // ROIC = (15000 * 0.75) / (80000 + 50000 - 20000) * 100 = 10.23%
      final expectedRoic = (15000 * 0.75) / (80000 + 50000 - 20000) * 100;
      expect(metrics.roic, closeTo(expectedRoic, 0.01));

      // ROE = 10000 / 80000 * 100 = 12.5%
      expect(metrics.roe, equals(12.5));

      // FCF/NI = 10000 / 10000 * 100 = 100%
      expect(metrics.fcfToNetIncome, equals(100.0));

      // PEG = 20.0 / 15.0 = 1.333...
      expect(metrics.pegRatio, closeTo(1.333, 0.01));
    });

    test('returns null for metrics with insufficient data', () {
      const inputs = FinancialInputs(
        companyName: 'Test Corp',
        ticker: 'TEST',
        revenue: 100000,
        operatingIncome: 15000,
        netIncome: -5000, // negative — P/E should be null
        freeCashFlow: -2000, // negative — P/FCF should be null
        marketCap: 200000,
        totalDebt: 50000,
        cashAndEquivalents: 20000,
        ebitda: 20000,
        totalEquity: 0, // zero — P/B, ROE should be null
      );

      final metrics = DerivedMetrics.fromInputs(inputs);

      expect(metrics.peRatio, isNull);
      expect(metrics.pToFcf, isNull);
      expect(metrics.pbRatio, isNull);
      expect(metrics.roe, isNull);
      expect(metrics.fcfToNetIncome, isNull); // netIncome <= 0
      expect(metrics.pegRatio, isNull); // no growth rate provided
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
        totalEquity: 80000,
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

    test('grades A when all criteria pass for Buffett (12 criteria)', () {
      const inputs = FinancialInputs(
        companyName: 'Excellent Corp',
        ticker: 'EXCL',
        revenue: 100000,
        operatingIncome: 20000, // 20% margin ✓
        netIncome: 12000, // 12% margin ✓
        freeCashFlow: 12000, // 6% FCF yield ✓
        marketCap: 200000,
        totalDebt: 30000,
        cashAndEquivalents: 20000, // Net debt = 10000
        ebitda: 25000, // Leverage = 0.4x ✓
        totalEquity: 50000,
        earningsGrowthRate: 15.0,
        // P/E = 200000/12000 = 16.67 (under 20) ✓
        // EV/EBITDA = 210000/25000 = 8.4 (under 14) ✓
        // P/FCF = 200000/12000 = 16.67 (under 18) ✓
        // P/B = 200000/50000 = 4.0 (under 5) ✓
        // ROIC = (20000*0.75)/(50000+30000-20000)*100 = 25% (above 15%) ✓
        // ROE = 12000/50000*100 = 24% (above 15%) ✓
        // FCF/NI = 12000/12000*100 = 100% (above 80%) ✓
        // PEG = 16.67/15.0 = 1.11 (under 2.0) ✓
      );

      final result = service.analyze(inputs, InvestorProfile.buffett);

      expect(result.grade, equals('A'));
      expect(result.score, equals(100));
      expect(result.criteria.length, equals(12));
      expect(result.criteria.every((c) => c.passed), isTrue);
    });

    test('grades F when almost no criteria pass', () {
      const inputs = FinancialInputs(
        companyName: 'Poor Corp',
        ticker: 'POOR',
        revenue: 100000,
        operatingIncome: 5000, // 5% margin (below 15%) ✗
        netIncome: 2000, // 2% margin (below 10%) ✗
        freeCashFlow: 4000, // 2% FCF yield (below 5%) ✗
        marketCap: 200000,
        totalDebt: 100000,
        cashAndEquivalents: 10000, // Net debt = 90000
        ebitda: 20000, // Leverage = 4.5x (above 2x) ✗
        totalEquity: 30000,
        // P/E = 100 ✗, EV/EBITDA = 14.5 ✗, P/FCF = 50 ✗, P/B = 6.67 ✗
        // ROIC = 3.125% ✗, ROE = 6.67% ✗
        // FCF/NI = 200% ✓ — this one passes
        // No PEG (no growth rate) → 11 criteria total
      );

      final result = service.analyze(inputs, InvestorProfile.buffett);

      // 1 out of 11 passes (FCF/NI), score = 9%, grade = F
      expect(result.grade, equals('F'));
      expect(result.criteria.length, equals(11)); // no PEG without growth rate
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
        totalEquity: 60000,
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

    test('all investors have 12 criteria when all data available', () {
      const inputs = FinancialInputs(
        companyName: 'Test Corp',
        ticker: 'TEST',
        revenue: 100000,
        operatingIncome: 30000,
        netIncome: 20000,
        freeCashFlow: 15000,
        marketCap: 200000,
        totalDebt: 30000,
        cashAndEquivalents: 20000,
        ebitda: 35000,
        totalEquity: 80000,
        earningsGrowthRate: 15.0,
      );

      for (final profile in InvestorProfile.all) {
        final result = service.analyze(inputs, profile);
        expect(result.criteria.length, equals(12),
            reason: '${profile.name} should have 12 criteria with all data');
      }
    });

    test('PEG criterion only added when earningsGrowthRate is provided', () {
      const inputsWithGrowth = FinancialInputs(
        companyName: 'Growth Corp',
        ticker: 'GROW',
        revenue: 100000,
        operatingIncome: 15000,
        netIncome: 10000,
        freeCashFlow: 8000,
        marketCap: 200000,
        totalDebt: 30000,
        cashAndEquivalents: 20000,
        ebitda: 20000,
        totalEquity: 80000,
        earningsGrowthRate: 20.0,
      );

      const inputsWithoutGrowth = FinancialInputs(
        companyName: 'Growth Corp',
        ticker: 'GROW',
        revenue: 100000,
        operatingIncome: 15000,
        netIncome: 10000,
        freeCashFlow: 8000,
        marketCap: 200000,
        totalDebt: 30000,
        cashAndEquivalents: 20000,
        ebitda: 20000,
        totalEquity: 80000,
      );

      final withGrowth =
          service.analyze(inputsWithGrowth, InvestorProfile.lynch);
      final withoutGrowth =
          service.analyze(inputsWithoutGrowth, InvestorProfile.lynch);

      final hasPeg = (AnalysisResult r) =>
          r.criteria.any((c) => c.name == 'PEG Ratio');

      expect(hasPeg(withGrowth), isTrue);
      expect(hasPeg(withoutGrowth), isFalse);
    });

    test('analyzeAll returns results for all 6 profiles', () {
      const inputs = FinancialInputs(
        companyName: 'Test Corp',
        ticker: 'TEST',
        revenue: 100000,
        operatingIncome: 15000,
        netIncome: 10000,
        freeCashFlow: 8000,
        marketCap: 200000,
        totalDebt: 30000,
        cashAndEquivalents: 20000,
        ebitda: 20000,
        totalEquity: 80000,
      );

      final results = service.analyzeAll(inputs);

      expect(results.length, equals(6));
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

    test('all profiles have all 12 thresholds set', () {
      for (final profile in InvestorProfile.all) {
        expect(profile.maxPeRatio, isNotNull,
            reason: '${profile.name} maxPeRatio');
        expect(profile.maxEvToEbitda, isNotNull,
            reason: '${profile.name} maxEvToEbitda');
        expect(profile.maxPToFcf, isNotNull,
            reason: '${profile.name} maxPToFcf');
        expect(profile.maxPbRatio, isNotNull,
            reason: '${profile.name} maxPbRatio');
        expect(profile.minRoic, isNotNull,
            reason: '${profile.name} minRoic');
        expect(profile.minRoe, isNotNull,
            reason: '${profile.name} minRoe');
        expect(profile.minFcfToNetIncome, isNotNull,
            reason: '${profile.name} minFcfToNetIncome');
        expect(profile.maxPegRatio, isNotNull,
            reason: '${profile.name} maxPegRatio');
      }
    });
  });
}
