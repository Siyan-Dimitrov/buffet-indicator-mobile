import 'package:flutter/material.dart';

import '../models/financial_data.dart';

class MetricsDashboard extends StatelessWidget {
  final DerivedMetrics metrics;
  final InvestorProfile profile;
  final List<CriterionResult> criteria;

  const MetricsDashboard({
    super.key,
    required this.metrics,
    required this.profile,
    required this.criteria,
  });

  /// Look up pass/fail for a criterion by name.
  /// Returns null if the metric wasn't evaluated (e.g. data unavailable).
  bool? _passed(String criterionName) {
    for (final c in criteria) {
      if (c.name == criterionName) return c.passed;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildMetricItems();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.dashboard_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'All Computed Metrics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Green = pass, Red = fail for ${profile.name}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMetricItems() {
    return [
      _MetricChip(
        label: 'FCF Yield',
        value: '${metrics.fcfYield.toStringAsFixed(1)}%',
        passed: _passed('FCF Yield'),
      ),
      _MetricChip(
        label: 'Op Margin',
        value: '${metrics.operatingMargin.toStringAsFixed(1)}%',
        passed: _passed('Operating Margin'),
      ),
      _MetricChip(
        label: 'Net Margin',
        value: '${metrics.netMargin.toStringAsFixed(1)}%',
        passed: _passed('Net Margin'),
      ),
      _MetricChip(
        label: 'Leverage',
        value: '${metrics.leverage.toStringAsFixed(2)}x',
        passed: _passed('Leverage'),
      ),
      _MetricChip(
        label: 'P/E',
        value: metrics.peRatio != null
            ? '${metrics.peRatio!.toStringAsFixed(1)}x'
            : 'N/A',
        passed: _passed('P/E Ratio'),
      ),
      _MetricChip(
        label: 'EV/EBITDA',
        value: metrics.evToEbitda != null
            ? '${metrics.evToEbitda!.toStringAsFixed(1)}x'
            : 'N/A',
        passed: _passed('EV/EBITDA'),
      ),
      _MetricChip(
        label: 'P/FCF',
        value: metrics.pToFcf != null
            ? '${metrics.pToFcf!.toStringAsFixed(1)}x'
            : 'N/A',
        passed: _passed('P/FCF'),
      ),
      _MetricChip(
        label: 'P/B',
        value: metrics.pbRatio != null
            ? '${metrics.pbRatio!.toStringAsFixed(2)}x'
            : 'N/A',
        passed: _passed('P/B Ratio'),
      ),
      _MetricChip(
        label: 'ROIC',
        value: metrics.roic != null
            ? '${metrics.roic!.toStringAsFixed(1)}%'
            : 'N/A',
        passed: _passed('ROIC'),
      ),
      _MetricChip(
        label: 'ROE',
        value: metrics.roe != null
            ? '${metrics.roe!.toStringAsFixed(1)}%'
            : 'N/A',
        passed: _passed('ROE'),
      ),
      _MetricChip(
        label: 'FCF/NI',
        value: metrics.fcfToNetIncome != null
            ? '${metrics.fcfToNetIncome!.toStringAsFixed(0)}%'
            : 'N/A',
        passed: _passed('FCF/Net Income'),
      ),
      _MetricChip(
        label: 'PEG',
        value: metrics.pegRatio != null
            ? '${metrics.pegRatio!.toStringAsFixed(2)}x'
            : 'N/A',
        passed: _passed('PEG Ratio'),
      ),
    ];
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final bool? passed; // null = not evaluated (data unavailable)

  const _MetricChip({
    required this.label,
    required this.value,
    this.passed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Color bgColor;
    final Color borderColor;
    final Color valueColor;
    final Color labelColor;

    if (passed == true) {
      bgColor = Colors.green.withOpacity(0.12);
      borderColor = Colors.green.withOpacity(0.4);
      valueColor = Colors.green.shade700;
      labelColor = Colors.green.shade800;
    } else if (passed == false) {
      bgColor = Colors.red.withOpacity(0.12);
      borderColor = Colors.red.withOpacity(0.4);
      valueColor = Colors.red.shade700;
      labelColor = Colors.red.shade800;
    } else {
      // Not evaluated (metric couldn't be computed)
      bgColor = scheme.surfaceContainerHighest;
      borderColor = Colors.transparent;
      valueColor = scheme.onSurface;
      labelColor = scheme.outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: labelColor,
                ),
          ),
        ],
      ),
    );
  }
}
