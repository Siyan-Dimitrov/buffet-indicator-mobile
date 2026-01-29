import 'package:flutter_test/flutter_test.dart';

import 'package:buffet_indicator/models/xbrl_filing_entry.dart';

void main() {
  group('XbrlFilingEntry', () {
    test('fromJson parses correctly', () {
      final entry = XbrlFilingEntry.fromJson({
        'val': 100000000.0,
        'end': '2024-12-31',
        'start': '2024-01-01',
        'form': '10-K',
        'fy': 2024,
        'fp': 'FY',
      });

      expect(entry.val, equals(100000000.0));
      expect(entry.end, equals('2024-12-31'));
      expect(entry.start, equals('2024-01-01'));
      expect(entry.form, equals('10-K'));
      expect(entry.fy, equals(2024));
      expect(entry.fp, equals('FY'));
    });

    test('periodDays calculates correctly for annual filing', () {
      const entry = XbrlFilingEntry(
        val: 100,
        end: '2024-12-31',
        start: '2024-01-01',
        form: '10-K',
        fy: 2024,
        fp: 'FY',
      );
      expect(entry.periodDays, equals(365));
    });

    test('periodDays is null for instant (balance sheet) entries', () {
      const entry = XbrlFilingEntry(
        val: 50000,
        end: '2024-12-31',
        form: '10-K',
        fy: 2024,
        fp: 'FY',
      );
      expect(entry.periodDays, isNull);
    });

    test('isAnnual detects 10-K forms', () {
      const entry = XbrlFilingEntry(
        val: 100,
        end: '2024-12-31',
        start: '2024-01-01',
        form: '10-K',
        fy: 2024,
        fp: 'FY',
      );
      expect(entry.isAnnual, isTrue);
      expect(entry.isQuarterly, isFalse);
    });

    test('isQuarterly detects 10-Q forms', () {
      const entry = XbrlFilingEntry(
        val: 25,
        end: '2024-03-31',
        start: '2024-01-01',
        form: '10-Q',
        fy: 2024,
        fp: 'Q1',
      );
      expect(entry.isQuarterly, isTrue);
      expect(entry.isAnnual, isFalse);
    });

    test('isInstant detects entries without start date', () {
      const entry = XbrlFilingEntry(
        val: 50000,
        end: '2024-12-31',
        form: '10-K',
        fy: 2024,
        fp: 'FY',
      );
      expect(entry.isInstant, isTrue);
    });

    test('isStandaloneQuarter detects ~90 day periods', () {
      const entry = XbrlFilingEntry(
        val: 25,
        end: '2024-03-31',
        start: '2024-01-01',
        form: '10-Q',
        fy: 2024,
        fp: 'Q1',
      );
      // 90 days, between 60-100
      expect(entry.isStandaloneQuarter, isTrue);
      expect(entry.isYtdCumulative, isFalse);
    });

    test('isYtdCumulative detects periods > 100 days and < 340 days', () {
      const entry = XbrlFilingEntry(
        val: 50,
        end: '2024-06-30',
        start: '2024-01-01',
        form: '10-Q',
        fy: 2024,
        fp: 'Q2',
      );
      // 181 days
      expect(entry.isYtdCumulative, isTrue);
      expect(entry.isStandaloneQuarter, isFalse);
    });

    test('quarterIndex returns correct values', () {
      expect(XbrlFilingEntry.quarterIndex('Q1'), equals(1));
      expect(XbrlFilingEntry.quarterIndex('Q2'), equals(2));
      expect(XbrlFilingEntry.quarterIndex('Q3'), equals(3));
      expect(XbrlFilingEntry.quarterIndex('Q4'), equals(4));
      expect(XbrlFilingEntry.quarterIndex('FY'), equals(0));
    });
  });
}
