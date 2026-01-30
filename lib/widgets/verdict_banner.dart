import 'package:flutter/material.dart';

import '../models/financial_data.dart';
import '../utils/investor_content.dart';
import '../utils/theme.dart';

class VerdictBanner extends StatelessWidget {
  final AnalysisResult result;

  const VerdictBanner({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final gradeColor = AppTheme.getGradeColor(result.grade);
    final verdict = InvestorContent.getVerdict(
      result.profile,
      result.grade,
      result.inputs.companyName,
    );

    final icon = _getVerdictIcon(result.grade);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gradeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gradeColor.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: gradeColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              verdict,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: gradeColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getVerdictIcon(String grade) {
    switch (grade) {
      case 'A':
      case 'B':
        return Icons.thumb_up;
      case 'C':
        return Icons.thumbs_up_down;
      case 'D':
      case 'F':
      default:
        return Icons.thumb_down;
    }
  }
}
