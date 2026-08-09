import 'package:flutter/material.dart';

import '../models/financial_data.dart';
import '../utils/theme.dart';
import 'metrics_dashboard.dart' show showMetricInfoSheet;

class MetricCard extends StatelessWidget {
  final CriterionResult criterion;
  final String? commentary;
  final InvestorProfile? profile;

  const MetricCard({
    super.key,
    required this.criterion,
    this.commentary,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.getStatusColor(context, criterion.passed);
    final statusLabel = criterion.passed ? 'Pass' : 'Needs attention';
    final actual =
        '${criterion.actualValue.toStringAsFixed(2)}${criterion.unit}';
    final target = '${criterion.threshold.toStringAsFixed(2)}${criterion.unit}';

    return Semantics(
      container: true,
      child: Card(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: statusColor, width: 4)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 10, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      criterion.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (profile != null)
                    IconButton(
                      tooltip: 'About ${criterion.name}',
                      onPressed: () => showMetricInfoSheet(
                        context,
                        criterion.name,
                        profile!,
                      ),
                      icon: const Icon(Icons.info_outline, size: 20),
                    ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          criterion.passed
                              ? Icons.check_circle
                              : Icons.error_outline,
                          size: 17,
                          color: statusColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          statusLabel,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Current $actual  →  Target ${criterion.isMaximum ? '≤' : '≥'} $target',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              if (commentary != null) ...[
                const SizedBox(height: 10),
                Text(
                  commentary!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
