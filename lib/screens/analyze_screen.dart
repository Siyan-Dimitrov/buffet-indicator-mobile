import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/financial_data.dart';
import '../providers/analysis_provider.dart';
import '../utils/theme.dart';
import '../widgets/grade_card.dart';
import '../widgets/metric_card.dart';
import '../widgets/prescription_card.dart';

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
    super.dispose();
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
    context.read<AnalysisProvider>().clearResult();
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
      body: Consumer<AnalysisProvider>(
        builder: (context, provider, child) {
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
                                provider.selectedProfile.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                provider.selectedProfile.description,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                              textCapitalization: TextCapitalization.characters,
                              validator: (value) =>
                                  value?.isEmpty == true ? 'Required' : null,
                            ),
                          ),
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
                      _buildNumberField(_netIncomeController, 'Net Income'),
                      _buildNumberField(_fcfController, 'Free Cash Flow'),
                      _buildNumberField(_marketCapController, 'Market Cap'),
                      _buildNumberField(_totalDebtController, 'Total Debt'),
                      _buildNumberField(_cashController, 'Cash & Equivalents'),
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
                              onPressed:
                                  provider.isLoading ? null : _submitAnalysis,
                              child: provider.isLoading
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
                if (provider.error != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        provider.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ],

                // Results
                if (provider.currentResult != null) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Grade card
                  GradeCard(result: provider.currentResult!),
                  const SizedBox(height: 16),

                  // Metrics cards
                  Text(
                    'Metrics vs Thresholds',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...provider.currentResult!.criteria.map(
                    (criterion) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: MetricCard(criterion: criterion),
                    ),
                  ),

                  // Prescriptions
                  if (provider.currentResult!.prescriptions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Prescriptions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    PrescriptionCard(
                      prescriptions: provider.currentResult!.prescriptions,
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
