import 'package:flutter/material.dart';

import '../models/financial_data.dart';
import '../utils/investor_content.dart';

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
    final items = _buildMetricItems(context);

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

  List<Widget> _buildMetricItems(BuildContext context) {
    Widget chip(String label, String metricName, String value) {
      return _MetricChip(
        label: label,
        value: value,
        passed: _passed(metricName),
        onInfoTap: () => showMetricInfoSheet(context, metricName, profile),
      );
    }

    return [
      chip('FCF Yield', 'FCF Yield',
          '${metrics.fcfYield.toStringAsFixed(1)}%'),
      chip('Op Margin', 'Operating Margin',
          '${metrics.operatingMargin.toStringAsFixed(1)}%'),
      chip('Net Margin', 'Net Margin',
          '${metrics.netMargin.toStringAsFixed(1)}%'),
      chip('Leverage', 'Leverage',
          '${metrics.leverage.toStringAsFixed(2)}x'),
      chip('P/E', 'P/E Ratio',
          metrics.peRatio != null
              ? '${metrics.peRatio!.toStringAsFixed(1)}x'
              : 'N/A'),
      chip('EV/EBITDA', 'EV/EBITDA',
          metrics.evToEbitda != null
              ? '${metrics.evToEbitda!.toStringAsFixed(1)}x'
              : 'N/A'),
      chip('P/FCF', 'P/FCF',
          metrics.pToFcf != null
              ? '${metrics.pToFcf!.toStringAsFixed(1)}x'
              : 'N/A'),
      chip('P/B', 'P/B Ratio',
          metrics.pbRatio != null
              ? '${metrics.pbRatio!.toStringAsFixed(2)}x'
              : 'N/A'),
      chip('ROIC', 'ROIC',
          metrics.roic != null
              ? '${metrics.roic!.toStringAsFixed(1)}%'
              : 'N/A'),
      chip('ROE', 'ROE',
          metrics.roe != null
              ? '${metrics.roe!.toStringAsFixed(1)}%'
              : 'N/A'),
      chip('FCF/NI', 'FCF/Net Income',
          metrics.fcfToNetIncome != null
              ? '${metrics.fcfToNetIncome!.toStringAsFixed(0)}%'
              : 'N/A'),
      chip('PEG', 'PEG Ratio',
          metrics.pegRatio != null
              ? '${metrics.pegRatio!.toStringAsFixed(2)}x'
              : 'N/A'),
    ];
  }
}

/// Shows a bottom sheet with the metric's general description and
/// investor-specific commentary.
void showMetricInfoSheet(
  BuildContext context,
  String metricName,
  InvestorProfile profile,
) {
  final description = InvestorContent.metricDescriptions[metricName];
  final commentary =
      InvestorContent.getMetricCommentary(profile, metricName);

  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metricName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (description != null) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (commentary != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  profile.name,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              commentary,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final bool? passed; // null = not evaluated (data unavailable)
  final VoidCallback? onInfoTap;

  const _MetricChip({
    required this.label,
    required this.value,
    this.passed,
    this.onInfoTap,
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

    return GestureDetector(
      onTap: onInfoTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
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
            const SizedBox(width: 4),
            Icon(
              Icons.info_outline,
              size: 14,
              color: labelColor,
            ),
          ],
        ),
      ),
    );
  }
}
