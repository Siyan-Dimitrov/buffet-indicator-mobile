import 'package:flutter/material.dart';

import '../models/financial_data.dart';
import '../utils/theme.dart';

class ComparisonTable extends StatelessWidget {
  final List<AnalysisResult> results;
  final ValueChanged<AnalysisResult>? onRowTap;

  const ComparisonTable({
    super.key,
    required this.results,
    this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    // Sort by score descending
    final sorted = List<AnalysisResult>.from(results)
      ..sort((a, b) => b.score.compareTo(a.score));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Multi-Investor Comparison',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              sorted.first.inputs.companyName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            ...sorted.map((result) => _buildRow(context, result)),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, AnalysisResult result) {
    final gradeColor = AppTheme.getGradeColor(result.grade);
    final passedCount = result.criteria.where((c) => c.passed).length;

    return InkWell(
      onTap: onRowTap != null ? () => onRowTap!(result) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // Grade circle
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: gradeColor.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: gradeColor, width: 2),
              ),
              child: Center(
                child: Text(
                  result.grade,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: gradeColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Investor name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.profile.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    '$passedCount/4 criteria passed',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),

            // Score
            Text(
              '${result.score}%',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: gradeColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),

            if (onRowTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
