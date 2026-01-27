import 'package:flutter/material.dart';

import '../models/financial_data.dart';
import '../utils/theme.dart';

class GradeCard extends StatelessWidget {
  final AnalysisResult result;

  const GradeCard({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final gradeColor = AppTheme.getGradeColor(result.grade);
    final passedCount = result.criteria.where((c) => c.passed).length;
    final totalCount = result.criteria.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Grade circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: gradeColor.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: gradeColor,
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  result.grade,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: gradeColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.inputs.companyName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    result.inputs.ticker,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Score: ${result.score}%',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: gradeColor,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$passedCount/$totalCount passed',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
