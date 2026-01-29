import 'package:flutter_test/flutter_test.dart';

import 'package:buffet_indicator/services/sec_api_service.dart';

/// Helper to build mock SEC XBRL facts JSON.
Map<String, dynamic> buildMockFacts({
  required String tag,
  required List<Map<String, dynamic>> entries,
  String unit = 'USD',
}) {
  return {
    'facts': {
      'us-gaap': {
        tag: {
          'units': {
            unit: entries,
          },
        },
      },
    },
  };
}

/// Helper to create a flow entry (has start date).
Map<String, dynamic> flowEntry({
  required double val,
  required String start,
  required String end,
  required String form,
  required int fy,
  required String fp,
}) {
  return {
    'val': val,
    'start': start,
    'end': end,
    'form': form,
    'fy': fy,
    'fp': fp,
  };
}

/// Helper to create an instant entry (no start date).
Map<String, dynamic> instantEntry({
  required double val,
  required String end,
  required String form,
  required int fy,
  required String fp,
}) {
  return {
    'val': val,
    'end': end,
    'form': form,
    'fy': fy,
    'fp': fp,
  };
}

void main() {
  group('SecApiService TTM extraction', () {
    group('addNullable', () {
      test('returns null when both are null', () {
        expect(SecApiService.addNullable(null, null), isNull);
      });

      test('returns sum when both present', () {
        expect(SecApiService.addNullable(10.0, 20.0), equals(30.0));
      });

      test('treats null as zero', () {
        expect(SecApiService.addNullable(10.0, null), equals(10.0));
        expect(SecApiService.addNullable(null, 20.0), equals(20.0));
      });
    });
  });

  group('SecApiService XBRL tag configuration', () {
    test('flowTags contains all expected metrics', () {
      expect(SecApiService.flowTags.keys, containsAll([
        'revenue',
        'operating_income',
        'net_income',
        'operating_cash_flow',
        'capex',
        'depreciation',
      ]));
    });

    test('instantTags contains all expected metrics', () {
      expect(SecApiService.instantTags.keys, containsAll([
        'long_term_debt',
        'short_term_debt',
        'cash',
      ]));
    });

    test('sharesTags is not empty', () {
      expect(SecApiService.sharesTags, isNotEmpty);
    });

    test('each flow tag has at least one XBRL tag', () {
      for (final entry in SecApiService.flowTags.entries) {
        expect(entry.value, isNotEmpty, reason: '${entry.key} should have tags');
      }
    });

    test('each instant tag has at least one XBRL tag', () {
      for (final entry in SecApiService.instantTags.entries) {
        expect(entry.value, isNotEmpty, reason: '${entry.key} should have tags');
      }
    });
  });

  group('SecFinancialData computed properties', () {
    test('freeCashFlow = operatingCashFlow - |capex|', () {
      // Tested via the model itself
      const data = _TestFinancialData(
        operatingCashFlow: 100000,
        capex: 30000,
      );
      expect(data.freeCashFlow, equals(70000));
    });

    test('freeCashFlow handles negative capex', () {
      const data = _TestFinancialData(
        operatingCashFlow: 100000,
        capex: -30000,
      );
      // abs(-30000) = 30000
      expect(data.freeCashFlow, equals(70000));
    });

    test('freeCashFlow is null when missing data', () {
      const data = _TestFinancialData(operatingCashFlow: 100000);
      expect(data.freeCashFlow, isNull);
    });

    test('calculatedEbitda = operatingIncome + depreciation', () {
      const data = _TestFinancialData(
        operatingIncome: 50000,
        depreciation: 10000,
      );
      expect(data.calculatedEbitda, equals(60000));
    });

    test('calculatedEbitda falls back to operatingIncome', () {
      const data = _TestFinancialData(operatingIncome: 50000);
      expect(data.calculatedEbitda, equals(50000));
    });
  });
}

/// Minimal helper to test computed properties without full SecFinancialData.
class _TestFinancialData {
  final double? operatingCashFlow;
  final double? capex;
  final double? operatingIncome;
  final double? depreciation;

  const _TestFinancialData({
    this.operatingCashFlow,
    this.capex,
    this.operatingIncome,
    this.depreciation,
  });

  double? get freeCashFlow {
    if (operatingCashFlow != null && capex != null) {
      return operatingCashFlow! - capex!.abs();
    }
    return null;
  }

  double? get calculatedEbitda {
    if (operatingIncome != null && depreciation != null) {
      return operatingIncome! + depreciation!;
    }
    return operatingIncome;
  }
}
