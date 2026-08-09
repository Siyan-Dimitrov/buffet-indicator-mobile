import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:buffet_indicator/models/financial_data.dart';
import 'package:buffet_indicator/services/analysis_service.dart';
import 'package:buffet_indicator/utils/theme.dart';
import 'package:buffet_indicator/widgets/grade_card.dart';

void main() {
  const inputs = FinancialInputs(
    companyName: 'Sample Quality Co.',
    ticker: 'DEMO',
    revenue: 100000,
    operatingIncome: 24000,
    netIncome: 18000,
    freeCashFlow: 17000,
    marketCap: 300000,
    totalDebt: 35000,
    cashAndEquivalents: 25000,
    ebitda: 30000,
    totalEquity: 90000,
    earningsGrowthRate: 12,
  );

  testWidgets('grade summary states matched checks without relying on color',
      (tester) async {
    final result = AnalysisService().analyze(inputs, InvestorProfile.buffett);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: GradeCard(result: result),
          ),
        ),
      ),
    );

    final passed =
        result.criteria.where((criterion) => criterion.passed).length;
    expect(
      find.text(
          '$passed of ${AnalysisService.expectedCriteriaCount} checks matched'),
      findsOneWidget,
    );
    expect(find.text('Sample Quality Co.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'grade card remains usable at large text scale on a narrow screen',
      (tester) async {
    final result = AnalysisService().analyze(inputs, InvestorProfile.buffett);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 320,
                child: GradeCard(result: result),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Sample Quality Co.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
