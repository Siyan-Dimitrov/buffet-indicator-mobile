import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart' show Share;

import '../models/financial_data.dart';
import '../models/sec_financial_data.dart';
import '../providers/analysis_provider.dart';
import '../providers/sec_provider.dart';
import '../utils/investor_content.dart';
import '../widgets/comparison_table.dart';
import '../widgets/grade_card.dart';
import '../widgets/metric_card.dart';
import '../widgets/metrics_dashboard.dart';
import '../widgets/prescription_card.dart';
import '../widgets/ticker_search_field.dart';
import '../widgets/verdict_banner.dart';

class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _companyNameController = TextEditingController();
  final _tickerController = TextEditingController();
  final _revenueController = TextEditingController();
  final _operatingIncomeController = TextEditingController();
  final _netIncomeController = TextEditingController();
  final _fcfController = TextEditingController();
  final _marketCapController = TextEditingController();
  final _totalDebtController = TextEditingController();
  final _cashController = TextEditingController();
  final _ebitdaController = TextEditingController();
  final _totalEquityController = TextEditingController();
  final _earningsGrowthRateController = TextEditingController();
  final _stockPriceController = TextEditingController();

  double? _sharesDiluted;

  @override
  void initState() {
    super.initState();
    _stockPriceController.addListener(_onStockPriceChanged);
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _tickerController.dispose();
    _revenueController.dispose();
    _operatingIncomeController.dispose();
    _netIncomeController.dispose();
    _fcfController.dispose();
    _marketCapController.dispose();
    _totalDebtController.dispose();
    _cashController.dispose();
    _ebitdaController.dispose();
    _totalEquityController.dispose();
    _earningsGrowthRateController.dispose();
    _stockPriceController.dispose();
    super.dispose();
  }

  void _onStockPriceChanged() {
    if (_sharesDiluted == null) return;
    final price = double.tryParse(_stockPriceController.text);
    if (price != null) {
      final marketCap = price * _sharesDiluted!;
      _marketCapController.text = _formatForForm(marketCap);
    }
  }

  /// Convert raw dollars to millions for the form.
  String _formatForForm(double? value) {
    if (value == null) return '';
    return (value / 1e6).toStringAsFixed(2);
  }

  void _autoPopulate(SecFinancialData data) {
    _companyNameController.text = data.companyName;
    _tickerController.text = data.ticker;
    _revenueController.text = _formatForForm(data.revenue);
    _operatingIncomeController.text = _formatForForm(data.operatingIncome);
    _netIncomeController.text = _formatForForm(data.netIncome);
    _fcfController.text = _formatForForm(data.freeCashFlow);
    _totalDebtController.text = _formatForForm(data.totalDebt);
    _cashController.text = _formatForForm(data.cashAndEquivalents);
    _ebitdaController.text = _formatForForm(data.calculatedEbitda);
    _totalEquityController.text = _formatForForm(data.totalEquity);

    // Auto-fill earnings growth rate if calculable from SEC data
    if (data.earningsGrowthRate != null) {
      _earningsGrowthRateController.text =
          data.earningsGrowthRate!.toStringAsFixed(1);
    }

    _sharesDiluted = data.sharesDiluted;

    // Auto-fill stock price if available from Yahoo Finance
    if (data.currentStockPrice != null) {
      _stockPriceController.text = data.currentStockPrice!.toStringAsFixed(2);
      // _onStockPriceChanged listener will auto-calculate market cap
    } else {
      // If user already entered a stock price, calculate market cap
      final price = double.tryParse(_stockPriceController.text);
      if (price != null && _sharesDiluted != null) {
        final marketCap = price * _sharesDiluted!;
        _marketCapController.text = _formatForForm(marketCap);
      } else {
        _marketCapController.text = '';
      }
    }

    // Auto-analyze after populating
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _submitAnalysis();
    });
  }

  List<String> _optionalWarnings = [];

  FinancialInputs? _buildInputs() {
    if (!_formKey.currentState!.validate()) return null;
    final warnings = <String>[];

    // Parse optional earnings growth rate — never blocks submission
    double? earningsGrowthRate;
    final growthText = _earningsGrowthRateController.text.trim();
    if (growthText.isNotEmpty) {
      final parsed = double.tryParse(growthText);
      if (parsed == null || parsed <= 0) {
        warnings.add(
          'Earnings Growth Rate ignored — must be a positive number. '
          'PEG ratio will not be calculated.',
        );
      } else {
        earningsGrowthRate = parsed;
      }
    } else {
      warnings.add(
        'No Earnings Growth Rate provided — PEG ratio will not be calculated.',
      );
    }

    setState(() => _optionalWarnings = warnings);

    return FinancialInputs(
      companyName: _companyNameController.text,
      ticker: _tickerController.text.toUpperCase(),
      revenue: double.parse(_revenueController.text),
      operatingIncome: double.parse(_operatingIncomeController.text),
      netIncome: double.parse(_netIncomeController.text),
      freeCashFlow: double.parse(_fcfController.text),
      marketCap: double.parse(_marketCapController.text),
      totalDebt: double.parse(_totalDebtController.text),
      cashAndEquivalents: double.parse(_cashController.text),
      ebitda: double.parse(_ebitdaController.text),
      totalEquity: double.parse(_totalEquityController.text),
      earningsGrowthRate: earningsGrowthRate,
    );
  }

  void _submitAnalysis() {
    final inputs = _buildInputs();
    if (inputs != null) {
      context.read<AnalysisProvider>().analyze(inputs);
    }
  }

  void _compareAllInvestors() {
    final inputs = _buildInputs();
    if (inputs != null) {
      context.read<AnalysisProvider>().compareAll(inputs);
    }
  }

  void _shareResult(AnalysisResult result) {
    final text = InvestorContent.generateShareText(result);
    Share.share(text);
  }

  void _clearForm() {
    _companyNameController.clear();
    _tickerController.clear();
    _revenueController.clear();
    _operatingIncomeController.clear();
    _netIncomeController.clear();
    _fcfController.clear();
    _marketCapController.clear();
    _totalDebtController.clear();
    _cashController.clear();
    _ebitdaController.clear();
    _totalEquityController.clear();
    _earningsGrowthRateController.clear();
    _stockPriceController.clear();
    _sharesDiluted = null;
    _optionalWarnings = [];
    context.read<AnalysisProvider>().clearResult();
    context.read<SecProvider>().clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buffet Indicator'),
        actions: [
          PopupMenuButton<InvestorProfile>(
            icon: const Icon(Icons.person),
            tooltip: 'Select Investor Profile',
            onSelected: (profile) {
              context.read<AnalysisProvider>().selectProfile(profile);
            },
            itemBuilder: (context) => InvestorProfile.all
                .map(
                  (profile) => PopupMenuItem(
                    value: profile,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(profile.name),
                      subtitle: Text(
                        profile.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      body: Consumer2<AnalysisProvider, SecProvider>(
        builder: (context, analysisProvider, secProvider, child) {
          final hasResults = analysisProvider.currentResult != null;
          final hasComparison = analysisProvider.comparisonResults != null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ──────────────────────────────────
                // RESULTS SECTION (only when results exist)
                // ──────────────────────────────────
                if (hasResults) ...[
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Column(
                      key: ValueKey(analysisProvider.currentResult!.analyzedAt),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Verdict banner (hero)
                        VerdictBanner(result: analysisProvider.currentResult!),
                        const SizedBox(height: 16),

                        // 2. Grade card with share button
                        GradeCard(result: analysisProvider.currentResult!),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.tonalIcon(
                            onPressed: () =>
                                _shareResult(analysisProvider.currentResult!),
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('Share'),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 3. Comparison table (if available)
                        if (hasComparison) ...[
                          ComparisonTable(
                            results: analysisProvider.comparisonResults!,
                            onRowTap: (result) {
                              final provider =
                                  context.read<AnalysisProvider>();
                              provider.selectProfile(result.profile);
                              _submitAnalysis();
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 4. Metrics dashboard (all computed metrics)
                        MetricsDashboard(
                          metrics: analysisProvider.currentResult!.metrics,
                          profile: analysisProvider.currentResult!.profile,
                          criteria: analysisProvider.currentResult!.criteria,
                        ),
                        const SizedBox(height: 16),

                        // 5. Criteria cards with commentary
                        Text(
                          'Metrics vs Thresholds',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ...analysisProvider.currentResult!.criteria.map(
                          (criterion) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: MetricCard(
                              criterion: criterion,
                              commentary:
                                  InvestorContent.getMetricCommentary(
                                analysisProvider.currentResult!.profile,
                                criterion.name,
                              ),
                              profile: analysisProvider.currentResult!.profile,
                            ),
                          ),
                        ),

                        // Prescriptions
                        if (analysisProvider
                            .currentResult!.prescriptions.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Prescriptions',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          PrescriptionCard(
                            prescriptions:
                                analysisProvider.currentResult!.prescriptions,
                            failingCriteria: analysisProvider
                                .currentResult!.criteria
                                .where((c) => !c.passed)
                                .toList(),
                          ),
                        ],

                        // Optional data warnings
                        if (_optionalWarnings.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Card(
                            elevation: 0,
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer
                                .withOpacity(0.5),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 20,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: _optionalWarnings
                                          .map((w) => Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 4),
                                                child: Text(
                                                  w,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSecondaryContainer,
                                                      ),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 5. Divider between results and form
                  const SizedBox(height: 24),
                  const Divider(thickness: 2),
                  const SizedBox(height: 16),
                ],

                // ──────────────────────────────────
                // FORM SECTION
                // ──────────────────────────────────

                // 6. Profile indicator
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                analysisProvider.selectedProfile.name,
                                style:
                                    Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                analysisProvider.selectedProfile.description,
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 7. Ticker search
                TickerSearchField(
                  onCompanySelected: (company) {
                    // Auto-populate will happen via the listener below
                  },
                ),

                // Listen for financial data and auto-populate
                if (secProvider.financialData != null) ...[
                  const SizedBox(height: 8),
                  _buildPeriodBanner(secProvider.financialData!),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: () =>
                        _autoPopulate(secProvider.financialData!),
                    child: const Text('Load & Analyze'),
                  ),
                ],

                if (secProvider.stockPriceError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    secProvider.stockPriceError!.userMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],

                if (secProvider.error != null) ...[
                  const SizedBox(height: 8),
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              secProvider.error!.userMessage,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                            ),
                          ),
                          if (secProvider.error!.isRetryable)
                            TextButton.icon(
                              onPressed: secProvider.isLoading
                                  ? null
                                  : () => secProvider.retry(),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Retry'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // 8. Input form (collapsible when results exist)
                _buildInputForm(context, analysisProvider, hasResults),

                // Error message
                if (analysisProvider.error != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              analysisProvider.error!,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Comparison table when no single result (standalone compare)
                if (!hasResults && hasComparison) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  ComparisonTable(
                    results: analysisProvider.comparisonResults!,
                    onRowTap: (result) {
                      final provider = context.read<AnalysisProvider>();
                      provider.selectProfile(result.profile);
                      _submitAnalysis();
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputForm(
    BuildContext context,
    AnalysisProvider analysisProvider,
    bool collapse,
  ) {
    final fields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Company Info section header
        Text(
          'Company Info',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const Divider(),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  hintText: 'e.g., Apple Inc.',
                ),
                validator: (value) =>
                    value?.isEmpty == true ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _tickerController,
                decoration: const InputDecoration(
                  labelText: 'Ticker',
                  hintText: 'AAPL',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) =>
                    value?.isEmpty == true ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Stock price field
        TextFormField(
          controller: _stockPriceController,
          decoration: const InputDecoration(
            labelText: 'Current Stock Price',
            hintText: 'e.g., 195.50',
            prefixText: '\$ ',
            helperText: 'Required for market cap calculation',
          ),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
        ),
        const SizedBox(height: 20),

        // Financial Data section header
        Text(
          'Financial Data',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const Divider(),
        const SizedBox(height: 4),
        Text(
          'All values in millions (\$)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),

        _buildNumberField(
          _revenueController,
          'Revenue',
          customValidator: (v) => v <= 0 ? 'Revenue must be positive' : null,
        ),
        _buildNumberField(
          _operatingIncomeController,
          'Operating Income',
          allowNegativeWarning: true,
        ),
        _buildNumberField(
          _netIncomeController,
          'Net Income',
          allowNegativeWarning: true,
        ),
        _buildNumberField(
          _fcfController,
          'Free Cash Flow',
          allowNegativeWarning: true,
        ),
        _buildNumberField(
          _marketCapController,
          'Market Cap',
          customValidator: (v) =>
              v <= 0 ? 'Market cap must be positive' : null,
        ),
        _buildNumberField(
          _totalDebtController,
          'Total Debt',
          customValidator: (v) =>
              v < 0 ? 'Debt cannot be negative' : null,
        ),
        _buildNumberField(
          _cashController,
          'Cash & Equivalents',
          customValidator: (v) =>
              v < 0 ? 'Cash cannot be negative' : null,
        ),
        _buildNumberField(
          _ebitdaController,
          'EBITDA',
          customValidator: (v) =>
              v <= 0 ? 'EBITDA must be positive' : null,
        ),
        _buildNumberField(
          _totalEquityController,
          'Total Equity',
          customValidator: (v) =>
              v <= 0 ? 'Equity must be positive' : null,
        ),

        const SizedBox(height: 12),
        // Optional section header
        Text(
          'Optional',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const Divider(),
        const SizedBox(height: 8),
        _buildOptionalNumberField(
          _earningsGrowthRateController,
          'Earnings Growth Rate',
          suffix: '%',
          helperText: 'Annual EPS growth — needed for PEG ratio',
        ),
      ],
    );

    // 9. Action buttons (always visible, outside the collapsible)
    final actionButtons = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _clearForm,
                child: const Text('Clear'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed:
                    analysisProvider.isLoading ? null : _submitAnalysis,
                child: analysisProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Analyze'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed:
              analysisProvider.isLoading ? null : _compareAllInvestors,
          icon: const Icon(Icons.compare_arrows, size: 18),
          label: const Text('Compare All Investors'),
        ),
      ],
    );

    // Form wraps everything so _formKey.currentState is always accessible
    if (collapse) {
      return Form(
        key: _formKey,
        child: Column(
          children: [
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: ExpansionTile(
                title: const Text('Financial Inputs'),
                subtitle: const Text('Tap to edit inputs'),
                leading: const Icon(Icons.edit_note),
                initiallyExpanded: false,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: fields,
                  ),
                ],
              ),
            ),
            actionButtons,
          ],
        ),
      );
    }

    // No results — show form expanded normally
    return Form(
      key: _formKey,
      child: Column(
        children: [
          fields,
          actionButtons,
        ],
      ),
    );
  }

  Widget _buildPeriodBanner(SecFinancialData data) {
    final priceInfo = data.stockPriceAsOf != null
        ? ' · Price as of ${DateFormat.jm().format(data.stockPriceAsOf!)}'
        : '';

    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Data: ${data.periodDescription}$priceInfo',
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (data.isTtm)
              const Chip(
                label: Text('TTM'),
                labelStyle: TextStyle(fontSize: 11),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.all(0),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField(
    TextEditingController controller,
    String label, {
    String? Function(double value)? customValidator,
    bool allowNegativeWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          suffixText: 'M',
          suffixIcon: allowNegativeWarning
              ? _buildNegativeWarningIcon(controller)
              : null,
        ),
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
        ],
        validator: (value) {
          if (value?.isEmpty == true) return 'Required';
          final parsed = double.tryParse(value!);
          if (parsed == null) return 'Invalid number';
          if (customValidator != null) return customValidator(parsed);
          return null;
        },
      ),
    );
  }

  Widget? _buildNegativeWarningIcon(TextEditingController controller) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final parsed = double.tryParse(value.text);
        if (parsed != null && parsed < 0) {
          return Tooltip(
            message: 'Negative value — will impact grade',
            child: Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 20,
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildOptionalNumberField(
    TextEditingController controller,
    String label, {
    String? suffix,
    String? helperText,
    String? Function(double value)? customValidator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: '$label (optional)',
          suffixText: suffix,
          helperText: helperText,
        ),
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
        ],
        validator: (value) {
          if (value == null || value.isEmpty) return null; // optional
          final parsed = double.tryParse(value);
          if (parsed == null) return 'Invalid number';
          if (customValidator != null) return customValidator(parsed);
          return null;
        },
      ),
    );
  }
}
