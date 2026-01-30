import 'package:flutter/material.dart';

import '../models/financial_data.dart';
import '../utils/theme.dart';

class MetricCard extends StatelessWidget {
  final CriterionResult criterion;
  final String? commentary;

  const MetricCard({
    super.key,
    required this.criterion,
    this.commentary,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor =
        criterion.passed ? AppTheme.passColor : AppTheme.failColor;

    // Calculate progress for the bar
    double progress;
    if (criterion.isMaximum) {
      // For maximum thresholds (like leverage), lower is better
      progress = criterion.threshold > 0
          ? (criterion.threshold - criterion.actualValue.clamp(0, criterion.threshold * 2)) /
              criterion.threshold
          : 0;
      progress = progress.clamp(0, 1);
    } else {
      // For minimum thresholds, higher is better
      progress = criterion.threshold > 0
          ? (criterion.actualValue / criterion.threshold).clamp(0, 1.5)
          : 0;
    }

    return Card(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: statusColor,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      criterion.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Icon(
                    criterion.passed ? Icons.check_circle : Icons.cancel,
                    color: statusColor,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 1),
                  minHeight: 10,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              const SizedBox(height: 8),

              // Values
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Actual: ${criterion.actualValue.toStringAsFixed(2)}${criterion.unit}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                  ),
                  Text(
                    '${criterion.isMaximum ? 'Max' : 'Min'}: ${criterion.threshold.toStringAsFixed(2)}${criterion.unit}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),

              // Commentary
              if (commentary != null) ...[
                const SizedBox(height: 8),
                Text(
                  commentary!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
