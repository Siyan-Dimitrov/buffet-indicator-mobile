import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/financial_data.dart';
import '../models/sec_financial_data.dart';
import '../providers/analysis_provider.dart';
import '../providers/sec_provider.dart';
import '../widgets/grade_card.dart';
import '../widgets/metric_card.dart';
import '../widgets/prescription_card.dart';
import '../widgets/ticker_search_field.dart';

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
  }

  void _submitAnalysis() {
    if (_formKey.currentState!.validate()) {
      final inputs = FinancialInputs(
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
      );

      context.read<AnalysisProvider>().analyze(inputs);
    }
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
    _stockPriceController.clear();
    _sharesDiluted = null;
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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile indicator
                Card(
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

                // Ticker search
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
                    child:
                        const Text('Auto-populate Financial Data'),
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

                // Input form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Company info
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
                              textCapitalization:
                                  TextCapitalization.characters,
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
                          helperText:
                              'Required for market cap calculation',
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*')),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Financial inputs
                      Text(
                        'Financial Data (in millions \$)',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),

                      _buildNumberField(_revenueController, 'Revenue'),
                      _buildNumberField(
                          _operatingIncomeController, 'Operating Income'),
                      _buildNumberField(
                          _netIncomeController, 'Net Income'),
                      _buildNumberField(_fcfController, 'Free Cash Flow'),
                      _buildNumberField(
                          _marketCapController, 'Market Cap'),
                      _buildNumberField(
                          _totalDebtController, 'Total Debt'),
                      _buildNumberField(
                          _cashController, 'Cash & Equivalents'),
                      _buildNumberField(_ebitdaController, 'EBITDA'),

                      const SizedBox(height: 16),

                      // Action buttons
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
                              onPressed: analysisProvider.isLoading
                                  ? null
                                  : _submitAnalysis,
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
                    ],
                  ),
                ),

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

                // Results
                if (analysisProvider.currentResult != null) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Grade card
                  GradeCard(result: analysisProvider.currentResult!),
                  const SizedBox(height: 16),

                  // Metrics cards
                  Text(
                    'Metrics vs Thresholds',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...analysisProvider.currentResult!.criteria.map(
                    (criterion) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: MetricCard(criterion: criterion),
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
                    ),
                  ],
                ],
              ],
            ),
          );
        },
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

  Widget _buildNumberField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          suffixText: 'M',
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
          if (double.tryParse(value!) == null) return 'Invalid number';
          return null;
        },
      ),
    );
  }
}
