import 'package:flutter/material.dart';

import '../models/financial_data.dart';
import '../utils/investor_content.dart';
import '../utils/theme.dart';

class VerdictBanner extends StatelessWidget {
  final AnalysisResult result;

  const VerdictBanner({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final gradeColor = AppTheme.getGradeColor(
      result.grade,
      Theme.of(context).brightness,
    );
    final verdict = InvestorContent.getVerdict(
      result.profile,
      result.grade,
      result.inputs.companyName,
    );

    return Semantics(
      container: true,
      label: verdict,
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: gradeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: gradeColor.withOpacity(0.45)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: gradeColor.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.fact_check_outlined, color: gradeColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                verdict,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: gradeColor,
                      height: 1.35,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
