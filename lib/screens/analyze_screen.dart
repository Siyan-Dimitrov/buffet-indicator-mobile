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
import '../widgets/analysis_result_view.dart';
import '../widgets/comparison_table.dart';
import '../widgets/ticker_search_field.dart';

class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inputsKey = GlobalKey();
  final _scrollController = ScrollController();

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
  bool _showInputs = false;
  int _searchFieldGeneration = 0;
  String? _appliedDataKey;
  String? _scheduledDataKey;
  List<String> _secDataWarnings = [];
  List<String> _optionalWarnings = [];

  @override
  void initState() {
    super.initState();
    _stockPriceController.addListener(_onStockPriceChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
    if (price == null) return;
    _marketCapController.text = _formatForForm(price * _sharesDiluted!);
  }

  String _formatForForm(double? value) {
    if (value == null) return '';
    return (value / 1e6).toStringAsFixed(2);
  }

  String _dataKey(SecFinancialData data) {
    return '${data.cik}|${data.periodEndDate?.toIso8601String()}|${data.currentStockPrice}';
  }

  void _scheduleAutoPopulate(SecFinancialData data) {
    final key = _dataKey(data);
    if (key == _appliedDataKey || key == _scheduledDataKey) return;
    _scheduledDataKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _autoPopulate(data, key);
    });
  }

  void _autoPopulate(SecFinancialData data, String key) {
    _companyNameController.text = data.companyName;
    _tickerController.text = data.ticker;

    // Clear values that must never carry over from a previously selected company.
    _earningsGrowthRateController.clear();
    _stockPriceController.clear();
    _marketCapController.clear();
    _sharesDiluted = data.sharesDiluted;

    final missing = <String>[];
    void populate(
      TextEditingController controller,
      double? value,
      String label,
    ) {
      controller.text = _formatForForm(value);
      if (value == null) missing.add(label);
    }

    populate(_revenueController, data.revenue, 'Revenue');
    populate(
        _operatingIncomeController, data.operatingIncome, 'Operating income');
    populate(_netIncomeController, data.netIncome, 'Net income');
    populate(_fcfController, data.freeCashFlow, 'Free cash flow');
    populate(_totalDebtController, data.totalDebt, 'Total debt');
    populate(_cashController, data.cashAndEquivalents, 'Cash and equivalents');
    populate(_ebitdaController, data.calculatedEbitda, 'EBITDA');
    populate(_totalEquityController, data.totalEquity, 'Total equity');

    if (data.earningsGrowthRate != null && data.earningsGrowthRate! > 0) {
      _earningsGrowthRateController.text =
          data.earningsGrowthRate!.toStringAsFixed(1);
    }

    if (data.currentStockPrice != null && data.sharesDiluted != null) {
      _stockPriceController.text = data.currentStockPrice!.toStringAsFixed(2);
      _marketCapController.text = _formatForForm(
        data.currentStockPrice! * data.sharesDiluted!,
      );
    } else {
      missing.add('Market cap');
    }

    setState(() {
      _appliedDataKey = key;
      _scheduledDataKey = null;
      _secDataWarnings = missing;
      _optionalWarnings = [];
      _showInputs = missing.isNotEmpty;
    });
  }

  FinancialInputs? _buildInputs() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return null;

    final warnings = <String>[];
    double? earningsGrowthRate;
    final growthText = _earningsGrowthRateController.text.trim();
    if (growthText.isNotEmpty) {
      final parsed = double.tryParse(growthText);
      if (parsed != null && parsed > 0) {
        earningsGrowthRate = parsed;
      } else {
        warnings.add(
            'Earnings growth was ignored, so the PEG check is unavailable.');
      }
    } else {
      warnings.add(
          'No earnings growth was available, so the PEG check is unavailable.');
    }
    setState(() => _optionalWarnings = warnings);

    return FinancialInputs(
      companyName: _companyNameController.text.trim(),
      ticker: _tickerController.text.trim().toUpperCase(),
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

  Future<void> _revealInvalidInputs() async {
    setState(() => _showInputs = true);
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final inputContext = _inputsKey.currentContext;
    if (inputContext != null) {
      if (!inputContext.mounted) return;
      await Scrollable.ensureVisible(
        inputContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.05,
      );
    }
  }

  Future<void> _submitAnalysis() async {
    FocusScope.of(context).unfocus();
    final inputs = _buildInputs();
    if (inputs == null) {
      await _revealInvalidInputs();
      return;
    }

    await context.read<AnalysisProvider>().analyze(inputs);
    if (!mounted) return;
    await _scrollToTop();
  }

  Future<void> _compareAllInvestors() async {
    FocusScope.of(context).unfocus();
    final inputs = _buildInputs();
    if (inputs == null) {
      await _revealInvalidInputs();
      return;
    }

    await context.read<AnalysisProvider>().compareAll(inputs);
    if (!mounted) return;
    await _scrollToTop();
  }

  Future<void> _compareResult(AnalysisResult result) async {
    await context.read<AnalysisProvider>().compareAll(result.inputs);
    if (!mounted) return;
    await _scrollToTop();
  }

  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _editInputs() {
    context.read<AnalysisProvider>().clearResult();
    setState(() => _showInputs = true);
  }

  void _clearForm() {
    for (final controller in [
      _companyNameController,
      _tickerController,
      _revenueController,
      _operatingIncomeController,
      _netIncomeController,
      _fcfController,
      _marketCapController,
      _totalDebtController,
      _cashController,
      _ebitdaController,
      _totalEquityController,
      _earningsGrowthRateController,
      _stockPriceController,
    ]) {
      controller.clear();
    }
    context.read<AnalysisProvider>().clearResult();
    context.read<SecProvider>().clearSelection();
    setState(() {
      _sharesDiluted = null;
      _showInputs = false;
      _searchFieldGeneration++;
      _appliedDataKey = null;
      _scheduledDataKey = null;
      _secDataWarnings = [];
      _optionalWarnings = [];
    });
    _scrollToTop();
  }

  void _loadDemo() {
    context.read<SecProvider>().clearSelection();
    context.read<AnalysisProvider>().clearResult();
    _companyNameController.text = 'Sample Quality Co.';
    _tickerController.text = 'DEMO';
    _revenueController.text = '100000';
    _operatingIncomeController.text = '24000';
    _netIncomeController.text = '18000';
    _fcfController.text = '17000';
    _marketCapController.text = '300000';
    _totalDebtController.text = '35000';
    _cashController.text = '25000';
    _ebitdaController.text = '30000';
    _totalEquityController.text = '90000';
    _earningsGrowthRateController.text = '12';
    _stockPriceController.clear();
    setState(() {
      _sharesDiluted = null;
      _showInputs = false;
      _searchFieldGeneration++;
      _appliedDataKey = null;
      _secDataWarnings = [];
      _optionalWarnings = [];
    });
  }

  Future<void> _showProfilePicker(AnalysisProvider provider) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a screening style',
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Each style uses different simplified targets. It does not reproduce an investor’s full process.',
                      style:
                          Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(sheetContext)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: InvestorProfile.all.map((profile) {
                    final selected = provider.selectedProfile == profile;
                    return RadioListTile<InvestorProfile>(
                      value: profile,
                      groupValue: provider.selectedProfile,
                      title: Text('${profile.name}-style'),
                      subtitle: Text(profile.description),
                      secondary:
                          selected ? const Icon(Icons.check_circle) : null,
                      onChanged: (value) {
                        if (value != null) provider.selectProfile(value);
                        Navigator.pop(sheetContext);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.travel_explore, size: 23),
            SizedBox(width: 9),
            Text('Value Lens'),
          ],
        ),
      ),
      body: Consumer2<AnalysisProvider, SecProvider>(
        builder: (context, analysisProvider, secProvider, _) {
          final financialData = secProvider.financialData;
          if (financialData != null) _scheduleAutoPopulate(financialData);

          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildCurrentView(
                    context,
                    analysisProvider,
                    secProvider,
                    financialData,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentView(
    BuildContext context,
    AnalysisProvider analysisProvider,
    SecProvider secProvider,
    SecFinancialData? financialData,
  ) {
    final result = analysisProvider.currentResult;
    if (result != null) {
      return AnalysisResultView(
        key: ValueKey('result-${result.analyzedAt.toIso8601String()}'),
        result: result,
        onShare: () => Share.share(InvestorContent.generateShareText(result)),
        onCompare: () => _compareResult(result),
        onEdit: _editInputs,
        onStartOver: _clearForm,
      );
    }

    final comparison = analysisProvider.comparisonResults;
    if (comparison != null) {
      return _buildComparisonView(context, analysisProvider, comparison);
    }

    return _buildSearchFlow(
      context,
      analysisProvider,
      secProvider,
      financialData,
    );
  }

  Widget _buildComparisonView(
    BuildContext context,
    AnalysisProvider provider,
    List<AnalysisResult> results,
  ) {
    return Column(
      key: const ValueKey('comparison'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Compare screening styles',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          'The same financial snapshot scored against six different rule sets.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 18),
        ComparisonTable(
          results: results,
          onRowTap: (selected) async {
            provider.selectProfile(selected.profile);
            await provider.analyze(selected.inputs);
            if (mounted) await _scrollToTop();
          },
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: provider.clearComparison,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to inputs'),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: _clearForm,
          child: const Text('Screen another company'),
        ),
        const SizedBox(height: 20),
        const _Disclaimer(),
      ],
    );
  }

  Widget _buildSearchFlow(
    BuildContext context,
    AnalysisProvider analysisProvider,
    SecProvider secProvider,
    SecFinancialData? financialData,
  ) {
    final hasPreparedData = _companyNameController.text.isNotEmpty;
    final dataReady = financialData != null && _appliedDataKey != null;

    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('search-flow'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Screen a stock in minutes',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Search a US company, review the available financials, and see which value-investing checks it matches.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 22),
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showProfilePicker(analysisProvider),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        Icons.tune,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Screening style',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${analysisProvider.selectedProfile.name}-style',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            analysisProvider.selectedProfile.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Find a company',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Search by ticker or company name. SEC filing data loads automatically.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 14),
                  TickerSearchField(
                    key: ValueKey(_searchFieldGeneration),
                  ),
                  if (secProvider.isLoading) ...[
                    const SizedBox(height: 14),
                    const _LoadingCard(),
                  ],
                  if (dataReady) ...[
                    const SizedBox(height: 14),
                    _buildDataReadyCard(context, financialData),
                  ],
                  if (secProvider.stockPriceError != null && dataReady) ...[
                    const SizedBox(height: 10),
                    _InlineNotice(
                      icon: Icons.price_change_outlined,
                      text: secProvider.stockPriceError!.userMessage,
                    ),
                  ],
                  if (secProvider.error != null &&
                      !secProvider.isCacheLoading &&
                      (secProvider.tickerCount > 0 ||
                          secProvider.selectedCompany != null)) ...[
                    const SizedBox(height: 12),
                    _ErrorCard(
                      message: secProvider.error!.userMessage,
                      onRetry: secProvider.error!.isRetryable
                          ? secProvider.retry
                          : null,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (!hasPreparedData)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _showInputs = true),
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Enter financials manually'),
                ),
                TextButton.icon(
                  onPressed: _loadDemo,
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Try a fictional sample'),
                ),
              ],
            ),
          Offstage(
            offstage: !_showInputs,
            child: Padding(
              key: _inputsKey,
              padding: const EdgeInsets.only(top: 12),
              child: _buildFinancialInputs(context),
            ),
          ),
          if (hasPreparedData && !_showInputs) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() => _showInputs = true),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Review all financial inputs'),
            ),
          ],
          if (hasPreparedData || _showInputs) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: analysisProvider.isLoading ? null : _submitAnalysis,
              icon: analysisProvider.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.fact_check_outlined),
              label: Text(
                _secDataWarnings.isNotEmpty
                    ? 'Complete inputs and run screen'
                    : 'Run ${analysisProvider.selectedProfile.name}-style screen',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed:
                  analysisProvider.isLoading ? null : _compareAllInvestors,
              icon: const Icon(Icons.compare_arrows),
              label: const Text('Compare all screening styles'),
            ),
          ],
          if (analysisProvider.error != null) ...[
            const SizedBox(height: 12),
            _ErrorCard(message: analysisProvider.error!),
          ],
          if (_optionalWarnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._optionalWarnings.map(
              (warning) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _InlineNotice(
                  icon: Icons.info_outline,
                  text: warning,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const _Disclaimer(),
        ],
      ),
    );
  }

  Widget _buildDataReadyCard(BuildContext context, SecFinancialData data) {
    final completeCount = 9 - _secDataWarnings.length;
    final priceInfo = data.stockPriceAsOf == null
        ? ''
        : ' • price checked ${DateFormat.jm().format(data.stockPriceAsOf!)}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _secDataWarnings.isEmpty
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.55)
            : Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _secDataWarnings.isEmpty
                    ? Icons.check_circle
                    : Icons.warning_amber_rounded,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data.companyName} (${data.ticker})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$completeCount of 9 required inputs found',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '${data.periodDescription}$priceInfo',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_secDataWarnings.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Still needed: ${_secDataWarnings.join(', ')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialInputs(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Review financial inputs',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        'Values are USD millions unless noted.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Hide financial inputs',
                  onPressed: () => setState(() => _showInputs = false),
                  icon: const Icon(Icons.expand_less),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth >= 560;
                final width = twoColumns
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: width,
                      child: _buildTextField(
                        _companyNameController,
                        'Company name',
                        hint: 'e.g. Apple Inc.',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _buildTextField(
                        _tickerController,
                        'Ticker',
                        hint: 'e.g. AAPL',
                        capitalization: TextCapitalization.characters,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _buildOptionalNumberField(
                        _stockPriceController,
                        'Current stock price',
                        prefix: r'$ ',
                        helperText:
                            'Used to calculate market cap when shares are available',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _buildNumberField(
                        _marketCapController,
                        'Market cap',
                        validator: (value) =>
                            value <= 0 ? 'Must be greater than zero' : null,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _buildNumberField(
                        _revenueController,
                        'Revenue',
                        validator: (value) =>
                            value <= 0 ? 'Must be greater than zero' : null,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _buildNumberField(
                        _operatingIncomeController,
                        'Operating income',
                        signed: true,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _buildNumberField(
                        _netIncomeController,
                        'Net income',
                        signed: true,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _buildNumberField(
                        _fcfController,
                        'Free cash flow',
                        signed: true,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _buildNumberField(
                        _totalDebtController,
                        'Total debt',
                        validator: (value) =>
                            value < 0 ? 'Cannot be negative' : null,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _buildNumberField(
                        _cashController,
                        'Cash and equivalents',
                        validator: (value) =>
                            value < 0 ? 'Cannot be negative' : null,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _buildNumberField(
                        _ebitdaController,
                        'EBITDA',
                        validator: (value) =>
                            value <= 0 ? 'Must be greater than zero' : null,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _buildNumberField(
                        _totalEquityController,
                        'Total equity',
                        validator: (value) =>
                            value <= 0 ? 'Must be greater than zero' : null,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _buildOptionalNumberField(
                        _earningsGrowthRateController,
                        'Earnings growth rate',
                        suffix: '%',
                        helperText: 'Optional; used for the PEG check',
                        signed: true,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _clearForm,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear inputs'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    String? hint,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      textCapitalization: capitalization,
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Required' : null,
    );
  }

  Widget _buildNumberField(
    TextEditingController controller,
    String label, {
    String? Function(double value)? validator,
    bool signed = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(
        decimal: true,
        signed: signed,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(signed ? r'^-?\d*\.?\d*' : r'^\d*\.?\d*'),
        ),
      ],
      decoration: InputDecoration(labelText: label, suffixText: 'M'),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        final parsed = double.tryParse(value);
        if (parsed == null) return 'Enter a valid number';
        return validator?.call(parsed);
      },
    );
  }

  Widget _buildOptionalNumberField(
    TextEditingController controller,
    String label, {
    String? prefix,
    String? suffix,
    String? helperText,
    bool signed = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(
        decimal: true,
        signed: signed,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(signed ? r'^-?\d*\.?\d*' : r'^\d*\.?\d*'),
        ),
      ],
      decoration: InputDecoration(
        labelText: '$label (optional)',
        prefixText: prefix,
        suffixText: suffix,
        helperText: helperText,
        helperMaxLines: 2,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return null;
        return double.tryParse(value) == null ? 'Enter a valid number' : null;
      },
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Expanded(child: Text('Loading SEC filings and a recent price…')),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InlineNotice({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19),
          const SizedBox(width: 9),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function()? onRetry;

  const _ErrorCard({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.shield_outlined,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Educational screening aid only. Not investment advice. SEC data can be incomplete or delayed; verify it before relying on a result.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}
