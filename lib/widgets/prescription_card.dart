import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/financial_data.dart';
import '../utils/theme.dart';

class PrescriptionCard extends StatelessWidget {
  final List<String> prescriptions;
  final List<CriterionResult> failingCriteria;

  const PrescriptionCard({
    super.key,
    required this.prescriptions,
    this.failingCriteria = const [],
  });

  @override
  Widget build(BuildContext context) {
    // Group failing criteria: "max" metrics are valuation (actual > threshold),
    // "min" metrics are quality (actual < threshold).
    final valuationCriteria =
        failingCriteria.where((c) => c.isMaximum).toList();
    final qualityCriteria =
        failingCriteria.where((c) => !c.isMaximum).toList();

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'What needs to improve',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bar charts for failing criteria
            if (failingCriteria.isNotEmpty) ...[
              if (qualityCriteria.isNotEmpty) ...[
                Text(
                  'Quality Metrics (below threshold)',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                ...qualityCriteria.map(
                  (c) => _buildBarRow(context, c),
                ),
                const SizedBox(height: 12),
              ],
              if (valuationCriteria.isNotEmpty) ...[
                Text(
                  'Valuation Metrics (above threshold)',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                ...valuationCriteria.map(
                  (c) => _buildBarRow(context, c),
                ),
                const SizedBox(height: 12),
              ],
              const Divider(),
              const SizedBox(height: 8),
            ],

            // Text prescriptions below the charts
            ...prescriptions.map(
              (prescription) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\u2022 ',
                      style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        prescription,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarRow(BuildContext context, CriterionResult criterion) {
    final actual = criterion.actualValue;
    final threshold = criterion.threshold;

    // Determine the max extent for the bar chart
    final maxVal = [actual.abs(), threshold.abs()].reduce((a, b) => a > b ? a : b);
    final chartMax = maxVal * 1.3; // 30% padding

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                criterion.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                '${_formatValue(actual)}${criterion.unit}'
                ' / ${_formatValue(threshold)}${criterion.unit}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Horizontal bar chart
          SizedBox(
            height: 28,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.start,
                maxY: 1,
                minY: 0,
                barTouchData: BarTouchData(enabled: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: 1,
                        width: 20,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                        rodStackItems: [
                          // Actual value bar (red)
                          BarChartRodStackItem(
                            0,
                            chartMax > 0
                                ? (actual.abs() / chartMax).clamp(0, 1)
                                : 0,
                            AppTheme.failColor.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: 1,
                        width: 20,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                        rodStackItems: [
                          // Threshold bar (green)
                          BarChartRodStackItem(
                            0,
                            chartMax > 0
                                ? (threshold.abs() / chartMax).clamp(0, 1)
                                : 0,
                            AppTheme.passColor.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              swapAnimationDuration: Duration.zero,
            ),
          ),

          // Legend
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.failColor.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Actual',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(width: 12),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.passColor.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Threshold',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}
