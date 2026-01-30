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
      elevation: 6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Colored header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Multi-Investor Comparison',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  sorted.first.inputs.companyName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer
                            .withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),
          // Rows
          ...List.generate(sorted.length, (index) {
            return _buildRow(context, sorted[index], index);
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, AnalysisResult result, int index) {
    final gradeColor = AppTheme.getGradeColor(result.grade);
    final passedCount = result.criteria.where((c) => c.passed).length;
    final isEven = index % 2 == 0;

    return InkWell(
      onTap: onRowTap != null ? () => onRowTap!(result) : null,
      child: Container(
        color: isEven
            ? Theme.of(context).colorScheme.surfaceContainerLowest
            : Theme.of(context).colorScheme.surfaceContainerLow,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            // Grade circle
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: gradeColor.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: gradeColor, width: 2.5),
              ),
              child: Center(
                child: Text(
                  result.grade,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: gradeColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

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
                  const SizedBox(height: 2),
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
