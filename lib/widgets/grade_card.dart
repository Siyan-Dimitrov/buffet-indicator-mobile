import 'package:flutter/material.dart';

import '../models/financial_data.dart';
import '../services/analysis_service.dart';
import '../utils/theme.dart';

class GradeCard extends StatelessWidget {
  final AnalysisResult result;

  const GradeCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final gradeColor = AppTheme.getGradeColor(
      result.grade,
      Theme.of(context).brightness,
    );
    final passedCount =
        result.criteria.where((criterion) => criterion.passed).length;
    final unavailable =
        AnalysisService.expectedCriteriaCount - result.criteria.length;

    final badge = Semantics(
      label: 'Grade ${result.grade}, score ${result.score} percent',
      excludeSemantics: true,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: gradeColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: gradeColor, width: 2),
        ),
        child: Center(
          child: Text(
            result.grade,
            style: TextStyle(
              fontSize: 40,
              height: 1,
              fontWeight: FontWeight.w800,
              color: gradeColor,
            ),
          ),
        ),
      ),
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          result.inputs.companyName,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 2),
        Text(
          '${result.inputs.ticker}  •  ${result.profile.name}-style',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          '$passedCount of ${AnalysisService.expectedCriteriaCount} checks matched',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: gradeColor,
              ),
        ),
        if (unavailable > 0) ...[
          const SizedBox(height: 2),
          Text(
            '$unavailable ${unavailable == 1 ? 'check was' : 'checks were'} unavailable',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 390) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  badge,
                  const SizedBox(height: 16),
                  details,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                badge,
                const SizedBox(width: 18),
                Expanded(child: details),
              ],
            );
          },
        ),
      ),
    );
  }
}
