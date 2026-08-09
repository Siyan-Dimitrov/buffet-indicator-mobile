import 'package:flutter/material.dart';

import '../models/financial_data.dart';
import '../services/analysis_service.dart';
import 'grade_card.dart';
import 'metric_card.dart';
import 'metrics_dashboard.dart';
import 'verdict_banner.dart';

class AnalysisResultView extends StatelessWidget {
  final AnalysisResult result;
  final VoidCallback? onShare;
  final VoidCallback? onCompare;
  final VoidCallback? onEdit;
  final VoidCallback? onStartOver;

  const AnalysisResultView({
    super.key,
    required this.result,
    this.onShare,
    this.onCompare,
    this.onEdit,
    this.onStartOver,
  });

  @override
  Widget build(BuildContext context) {
    final failed =
        result.criteria.where((criterion) => !criterion.passed).toList();
    final passed =
        result.criteria.where((criterion) => criterion.passed).toList();
    final unavailable =
        AnalysisService.expectedCriteriaCount - result.criteria.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GradeCard(result: result),
        const SizedBox(height: 12),
        VerdictBanner(result: result),
        if (unavailable > 0) ...[
          const SizedBox(height: 12),
          _CompletenessNotice(
            evaluated: result.criteria.length,
            unavailable: unavailable,
          ),
        ],
        const SizedBox(height: 24),
        _SectionHeader(
          title:
              failed.isEmpty ? 'No checks need attention' : 'Needs attention',
          subtitle: failed.isEmpty
              ? 'Every evaluated rule was matched.'
              : '${failed.length} ${failed.length == 1 ? 'check' : 'checks'} missed the selected target.',
        ),
        const SizedBox(height: 10),
        if (failed.isEmpty)
          const _AllClearCard()
        else
          ...failed.map(
            (criterion) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MetricCard(
                criterion: criterion,
                profile: result.profile,
              ),
            ),
          ),
        if (result.prescriptions.isNotEmpty) ...[
          const SizedBox(height: 6),
          _ChangeList(items: result.prescriptions),
        ],
        const SizedBox(height: 16),
        Card(
          child: ExpansionTile(
            leading: const Icon(Icons.check_circle_outline),
            title: Text('Matched checks (${passed.length})'),
            subtitle: const Text('See the rules this company passed'),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: passed
                .map(
                  (criterion) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: MetricCard(
                      criterion: criterion,
                      profile: result.profile,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ExpansionTile(
            leading: const Icon(Icons.calculate_outlined),
            title: const Text('All metrics and methodology'),
            subtitle: const Text('Review every calculated value'),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: [
              MetricsDashboard(
                metrics: result.metrics,
                profile: result.profile,
                criteria: result.criteria,
              ),
            ],
          ),
        ),
        if (onShare != null || onCompare != null) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (onCompare != null)
                OutlinedButton.icon(
                  onPressed: onCompare,
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('Compare styles'),
                ),
              if (onShare != null)
                OutlinedButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share result'),
                ),
            ],
          ),
        ],
        if (onEdit != null || onStartOver != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (onEdit != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onEdit,
                    child: const Text('Review inputs'),
                  ),
                ),
              if (onEdit != null && onStartOver != null)
                const SizedBox(width: 10),
              if (onStartOver != null)
                Expanded(
                  child: FilledButton(
                    onPressed: onStartOver,
                    child: const Text('Screen another'),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'This is a simplified research screen, not investment advice or a prediction. Verify source data and consider the wider business before making decisions.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _CompletenessNotice extends StatelessWidget {
  final int evaluated;
  final int unavailable;

  const _CompletenessNotice({
    required this.evaluated,
    required this.unavailable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.data_usage_outlined,
            color: Theme.of(context).colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$evaluated of ${AnalysisService.expectedCriteriaCount} checks were evaluated. '
              '$unavailable unavailable ${unavailable == 1 ? 'check counts' : 'checks count'} against the score so companies remain comparable.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllClearCard extends StatelessWidget {
  const _AllClearCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('No evaluated rule missed its target.'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeList extends StatelessWidget {
  final List<String> items;

  const _ChangeList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.route_outlined),
        title: const Text('What would need to change'),
        subtitle: const Text('Illustrative changes to reach missed targets'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(Icons.arrow_right, size: 18),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
