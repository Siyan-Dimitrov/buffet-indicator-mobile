# SEC EDGAR API Integration - Implementation Plan

> **Status:** Ready to implement
> **Created:** January 2026
> **Reference:** Python implementation at `C:\Dev\Buffet_indicator\src\screener\sec_api.py`

---

## Overview

Port the SEC EDGAR API client from the Python Buffet_indicator project to Dart/Flutter, enabling users to search for companies by ticker and auto-populate financial data from SEC filings.

This corresponds to **Phase 1: Core Data Integration** from ROADMAP.md.

---

## Key Design Decisions

### Stock Price Challenge
The SEC EDGAR API doesn't provide stock prices or market cap.

**Solution:** Hybrid approach where the user provides the current stock price, and we calculate market cap using `price × shares_diluted` from SEC data.

### Data Source
- SEC EDGAR API (free, no API key required)
- Company tickers: `https://www.sec.gov/files/company_tickers.json`
- Company facts: `https://data.sec.gov/api/xbrl/companyfacts/CIK{cik}.json`

### Rate Limiting
- Minimum 150ms between requests (SEC guideline: max 10 req/sec)
- User-Agent header required by SEC (format: `AppName/Version (contact@email.com)`)

---

## Reference: Python Implementation

The Python version is at `C:\Dev\Buffet_indicator\src\screener\sec_api.py`. Key components:

### Constants
```python
SEC_BASE_URL = "https://data.sec.gov"
SEC_TICKERS_URL = "https://www.sec.gov/files/company_tickers.json"

XBRL_TAGS = {
    "revenue": ["Revenues", "RevenueFromContractWithCustomerExcludingAssessedTax", "SalesRevenueNet"],
    "operating_income": ["OperatingIncomeLoss"],
    "net_income": ["NetIncomeLoss"],
    "total_debt": ["LongTermDebt", "ShortTermBorrowings", "Debt"],
    "cash": ["CashAndCashEquivalentsAtCarryingValue"],
    "ebitda": ["OperatingIncomeLoss"],  # Combined with depreciation
    "depreciation": ["DepreciationDepletionAndAmortization", "DepreciationAndAmortization"],
    "operating_cash_flow": ["NetCashProvidedByUsedInOperatingActivities"],
    "capex": ["PaymentsToAcquirePropertyPlantAndEquipment"],
    "shares_diluted": ["WeightedAverageNumberOfDilutedSharesOutstanding"],
}
```

### Key Classes
- `SECCompanyInfo` - CIK, ticker, name
- `SECFinancialData` - All financial metrics from XBRL
- `SECClient` - API client with rate limiting

### Key Methods
```python
def lookup_company(self, ticker: str) -> SECCompanyInfo | None
def search_companies(self, query: str, limit: int = 10) -> list[SECCompanyInfo]
def get_company_facts(self, cik: str) -> dict | None
def get_financial_data(self, cik: str) -> SECFinancialData | None
```

---

## New Files to Create

### 1. `lib/models/sec_company.dart`

```dart
/// Represents a company from SEC EDGAR database
class SecCompany {
  final String cik;      // CIK number (zero-padded to 10 digits)
  final String ticker;   // Stock symbol (e.g., "AAPL")
  final String name;     // Company name (e.g., "Apple Inc.")

  const SecCompany({
    required this.cik,
    required this.ticker,
    required this.name,
  });

  /// Parse from SEC company_tickers.json format
  factory SecCompany.fromJson(Map<String, dynamic> json) {
    return SecCompany(
      cik: json['cik_str'].toString().padLeft(10, '0'),
      ticker: json['ticker'] as String,
      name: json['title'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'cik_str': cik,
    'ticker': ticker,
    'title': name,
  };
}
```

### 2. `lib/models/sec_financial_data.dart`

```dart
/// Financial data parsed from SEC XBRL filings
class SecFinancialData {
  final String cik;
  final String ticker;
  final String companyName;

  // Core financial metrics (nullable - not all companies report all fields)
  final double? revenue;
  final double? operatingIncome;
  final double? netIncome;
  final double? totalDebt;
  final double? cashAndEquivalents;
  final double? ebitda;
  final double? operatingCashFlow;
  final double? capex;
  final double? sharesDiluted;
  final double? depreciation;

  // Metadata
  final DateTime? filingDate;
  final String? fiscalPeriod;  // e.g., "FY2024" or "Q4 2024"
  final String? form;          // e.g., "10-K" or "10-Q"

  const SecFinancialData({
    required this.cik,
    required this.ticker,
    required this.companyName,
    this.revenue,
    this.operatingIncome,
    this.netIncome,
    this.totalDebt,
    this.cashAndEquivalents,
    this.ebitda,
    this.operatingCashFlow,
    this.capex,
    this.sharesDiluted,
    this.depreciation,
    this.filingDate,
    this.fiscalPeriod,
    this.form,
  });

  /// Calculate Free Cash Flow = Operating Cash Flow - CapEx
  double? get freeCashFlow {
    if (operatingCashFlow != null && capex != null) {
      return operatingCashFlow! - capex!.abs();
    }
    return null;
  }

  /// Calculate EBITDA = Operating Income + Depreciation
  double? get calculatedEbitda {
    if (operatingIncome != null && depreciation != null) {
      return operatingIncome! + depreciation!;
    }
    return ebitda;
  }
}
```

### 3. `lib/services/sec_api_service.dart`

```dart
import 'package:dio/dio.dart';
import '../models/sec_company.dart';
import '../models/sec_financial_data.dart';

class SecApiService {
  static const String _baseUrl = 'https://data.sec.gov';
  static const String _tickersUrl = 'https://www.sec.gov/files/company_tickers.json';
  static const Duration _rateLimitDelay = Duration(milliseconds: 150);

  final Dio _dio;
  DateTime? _lastRequestTime;

  // XBRL tag mappings (same as Python version)
  static const Map<String, List<String>> xbrlTags = {
    'revenue': ['Revenues', 'RevenueFromContractWithCustomerExcludingAssessedTax', 'SalesRevenueNet'],
    'operating_income': ['OperatingIncomeLoss'],
    'net_income': ['NetIncomeLoss'],
    'total_debt': ['LongTermDebt', 'ShortTermBorrowings', 'Debt'],
    'cash': ['CashAndCashEquivalentsAtCarryingValue'],
    'depreciation': ['DepreciationDepletionAndAmortization', 'DepreciationAndAmortization'],
    'operating_cash_flow': ['NetCashProvidedByUsedInOperatingActivities'],
    'capex': ['PaymentsToAcquirePropertyPlantAndEquipment'],
    'shares_diluted': ['WeightedAverageNumberOfDilutedSharesOutstanding'],
  };

  SecApiService() : _dio = Dio() {
    _dio.options.headers['User-Agent'] = 'BuffetIndicator/1.0 (buffetindicator@example.com)';
  }

  /// Rate limit: ensure minimum delay between requests
  Future<void> _rateLimit() async {
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < _rateLimitDelay) {
        await Future.delayed(_rateLimitDelay - elapsed);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  /// Fetch all company tickers from SEC
  Future<List<SecCompany>> fetchAllTickers() async {
    await _rateLimit();
    final response = await _dio.get(_tickersUrl);
    final Map<String, dynamic> data = response.data;

    return data.values
        .map((json) => SecCompany.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get company facts (XBRL data) for a CIK
  Future<Map<String, dynamic>?> getCompanyFacts(String cik) async {
    await _rateLimit();
    final paddedCik = cik.padLeft(10, '0');
    try {
      final response = await _dio.get('$_baseUrl/api/xbrl/companyfacts/CIK$paddedCik.json');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // Company not found
      }
      rethrow;
    }
  }

  /// Extract latest value for a metric from XBRL facts
  double? _extractLatestValue(Map<String, dynamic> facts, List<String> tags) {
    final usGaap = facts['facts']?['us-gaap'] as Map<String, dynamic>?;
    if (usGaap == null) return null;

    for (final tag in tags) {
      final tagData = usGaap[tag] as Map<String, dynamic>?;
      if (tagData == null) continue;

      final units = tagData['units'] as Map<String, dynamic>?;
      final usdData = units?['USD'] as List<dynamic>?;
      if (usdData == null || usdData.isEmpty) continue;

      // Get most recent annual (10-K) or quarterly (10-Q) filing
      final annualFilings = usdData
          .where((f) => f['form'] == '10-K')
          .toList()
        ..sort((a, b) => (b['end'] as String).compareTo(a['end'] as String));

      if (annualFilings.isNotEmpty) {
        return (annualFilings.first['val'] as num).toDouble();
      }
    }
    return null;
  }

  /// Get parsed financial data for a company
  Future<SecFinancialData?> getFinancialData(SecCompany company) async {
    final facts = await getCompanyFacts(company.cik);
    if (facts == null) return null;

    return SecFinancialData(
      cik: company.cik,
      ticker: company.ticker,
      companyName: company.name,
      revenue: _extractLatestValue(facts, xbrlTags['revenue']!),
      operatingIncome: _extractLatestValue(facts, xbrlTags['operating_income']!),
      netIncome: _extractLatestValue(facts, xbrlTags['net_income']!),
      totalDebt: _extractLatestValue(facts, xbrlTags['total_debt']!),
      cashAndEquivalents: _extractLatestValue(facts, xbrlTags['cash']!),
      depreciation: _extractLatestValue(facts, xbrlTags['depreciation']!),
      operatingCashFlow: _extractLatestValue(facts, xbrlTags['operating_cash_flow']!),
      capex: _extractLatestValue(facts, xbrlTags['capex']!),
      sharesDiluted: _extractLatestValue(facts, xbrlTags['shares_diluted']!),
    );
  }
}
```

### 4. `lib/services/ticker_cache_service.dart`

```dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sec_company.dart';

class TickerCacheService {
  static const String _boxName = 'ticker_cache';
  static const String _tickersKey = 'tickers';
  static const String _lastUpdatedKey = 'last_updated';
  static const Duration _cacheExpiry = Duration(days: 7);

  late Box<dynamic> _box;
  List<SecCompany> _tickers = [];

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    await _loadFromCache();
  }

  Future<void> _loadFromCache() async {
    final cached = _box.get(_tickersKey) as List<dynamic>?;
    if (cached != null) {
      _tickers = cached
          .map((json) => SecCompany.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
  }

  bool get isCacheValid {
    final lastUpdated = _box.get(_lastUpdatedKey) as DateTime?;
    if (lastUpdated == null) return false;
    return DateTime.now().difference(lastUpdated) < _cacheExpiry;
  }

  Future<void> updateCache(List<SecCompany> tickers) async {
    _tickers = tickers;
    await _box.put(_tickersKey, tickers.map((t) => t.toJson()).toList());
    await _box.put(_lastUpdatedKey, DateTime.now());
  }

  /// Search tickers locally (fast, offline)
  List<SecCompany> search(String query, {int limit = 10}) {
    if (query.isEmpty) return [];

    final upperQuery = query.toUpperCase();
    final lowerQuery = query.toLowerCase();

    // Exact ticker match first
    final exactMatch = _tickers.where((t) => t.ticker.toUpperCase() == upperQuery);

    // Ticker starts with query
    final tickerStarts = _tickers.where((t) =>
        t.ticker.toUpperCase().startsWith(upperQuery) &&
        t.ticker.toUpperCase() != upperQuery);

    // Name contains query
    final nameContains = _tickers.where((t) =>
        t.name.toLowerCase().contains(lowerQuery) &&
        !t.ticker.toUpperCase().startsWith(upperQuery));

    return [...exactMatch, ...tickerStarts, ...nameContains].take(limit).toList();
  }

  int get tickerCount => _tickers.length;
}
```

### 5. `lib/providers/sec_provider.dart`

```dart
import 'package:flutter/foundation.dart';
import '../models/sec_company.dart';
import '../models/sec_financial_data.dart';
import '../services/sec_api_service.dart';
import '../services/ticker_cache_service.dart';

class SecProvider extends ChangeNotifier {
  final SecApiService _apiService;
  final TickerCacheService _cacheService;

  List<SecCompany> _searchResults = [];
  SecCompany? _selectedCompany;
  SecFinancialData? _financialData;
  bool _isLoading = false;
  String? _error;

  SecProvider({
    SecApiService? apiService,
    TickerCacheService? cacheService,
  })  : _apiService = apiService ?? SecApiService(),
        _cacheService = cacheService ?? TickerCacheService();

  // Getters
  List<SecCompany> get searchResults => _searchResults;
  SecCompany? get selectedCompany => _selectedCompany;
  SecFinancialData? get financialData => _financialData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize cache (call on app startup)
  Future<void> init() async {
    await _cacheService.init();
    if (!_cacheService.isCacheValid) {
      await refreshTickerCache();
    }
  }

  /// Refresh ticker cache from SEC
  Future<void> refreshTickerCache() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final tickers = await _apiService.fetchAllTickers();
      await _cacheService.updateCache(tickers);
    } catch (e) {
      _error = 'Failed to fetch tickers: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search companies (uses local cache)
  void searchCompanies(String query) {
    _searchResults = _cacheService.search(query);
    notifyListeners();
  }

  /// Select a company and fetch its financial data
  Future<void> selectCompany(SecCompany company) async {
    try {
      _selectedCompany = company;
      _financialData = null;
      _isLoading = true;
      _error = null;
      notifyListeners();

      _financialData = await _apiService.getFinancialData(company);
      if (_financialData == null) {
        _error = 'No financial data available for ${company.ticker}';
      }
    } catch (e) {
      _error = 'Failed to fetch data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear selection
  void clearSelection() {
    _selectedCompany = null;
    _financialData = null;
    _searchResults = [];
    _error = null;
    notifyListeners();
  }
}
```

### 6. `lib/widgets/ticker_search_field.dart`

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sec_company.dart';
import '../providers/sec_provider.dart';

class TickerSearchField extends StatefulWidget {
  final void Function(SecCompany company)? onCompanySelected;

  const TickerSearchField({super.key, this.onCompanySelected});

  @override
  State<TickerSearchField> createState() => _TickerSearchFieldState();
}

class _TickerSearchFieldState extends State<TickerSearchField> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<SecProvider>().searchCompanies(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Search Ticker',
            hintText: 'e.g., AAPL, MSFT',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: _onSearchChanged,
        ),
        Consumer<SecProvider>(
          builder: (context, provider, child) {
            if (provider.searchResults.isEmpty) {
              return const SizedBox.shrink();
            }
            return Card(
              margin: const EdgeInsets.only(top: 4),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: provider.searchResults.length,
                itemBuilder: (context, index) {
                  final company = provider.searchResults[index];
                  return ListTile(
                    title: Text(company.ticker),
                    subtitle: Text(
                      company.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      _controller.text = company.ticker;
                      provider.selectCompany(company);
                      widget.onCompanySelected?.call(company);
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
```

---

## Files to Modify

### `lib/screens/analyze_screen.dart`

Add at the top of the form:
1. `TickerSearchField` widget
2. "Stock Price" text field (required for market cap calculation)
3. "Auto-populate" button

When auto-populating:
```dart
void _autoPopulate(SecFinancialData data, double stockPrice) {
  final marketCap = stockPrice * (data.sharesDiluted ?? 0);

  _companyNameController.text = data.companyName;
  _tickerController.text = data.ticker;
  _revenueController.text = _formatNumber(data.revenue);
  _operatingIncomeController.text = _formatNumber(data.operatingIncome);
  _netIncomeController.text = _formatNumber(data.netIncome);
  _freeCashFlowController.text = _formatNumber(data.freeCashFlow);
  _marketCapController.text = _formatNumber(marketCap);
  _totalDebtController.text = _formatNumber(data.totalDebt);
  _cashController.text = _formatNumber(data.cashAndEquivalents);
  _ebitdaController.text = _formatNumber(data.calculatedEbitda);
}
```

### `lib/main.dart`

Add to providers:
```dart
ChangeNotifierProvider(create: (_) => SecProvider()..init()),
```

---

## Data Mapping: SEC → FinancialInputs

| FinancialInputs Field | SEC XBRL Source |
|-----------------------|-----------------|
| companyName | From company_tickers.json |
| ticker | From company_tickers.json |
| revenue | Revenues or RevenueFromContractWithCustomerExcludingAssessedTax |
| operatingIncome | OperatingIncomeLoss |
| netIncome | NetIncomeLoss |
| freeCashFlow | NetCashProvidedByUsedInOperatingActivities - PaymentsToAcquirePropertyPlantAndEquipment |
| marketCap | **User-provided price** × sharesDiluted |
| totalDebt | LongTermDebt + ShortTermBorrowings (or Debt) |
| cashAndEquivalents | CashAndCashEquivalentsAtCarryingValue |
| ebitda | OperatingIncomeLoss + DepreciationDepletionAndAmortization |

---

## Implementation Phases

### Phase 1: Core Services (Files 1-3)
1. Create `lib/models/sec_company.dart`
2. Create `lib/models/sec_financial_data.dart`
3. Create `lib/services/sec_api_service.dart`

### Phase 2: Caching & State (Files 4-5)
4. Create `lib/services/ticker_cache_service.dart`
5. Create `lib/providers/sec_provider.dart`

### Phase 3: UI Integration (Files 6 + modifications)
6. Create `lib/widgets/ticker_search_field.dart`
7. Modify `lib/screens/analyze_screen.dart`
8. Modify `lib/main.dart`

### Phase 4: Testing & Polish
9. Add unit tests for `SecApiService`
10. Add unit tests for `TickerCacheService`
11. Add widget tests for `TickerSearchField`
12. Integration testing

---

## Error Handling

| Error | User Message | Recovery |
|-------|--------------|----------|
| Network error | "Unable to connect. Check your internet connection." | Retry button |
| Rate limited | (Handled automatically with delay) | N/A |
| Company not found | "Company not found in SEC database" | Manual entry |
| Missing XBRL data | "Some fields could not be populated" | Show which fields, allow manual edit |
| Cache refresh failed | "Using cached data (last updated X days ago)" | Continue with old cache |

---

## Testing Checklist

- [ ] Search returns results for "AAPL"
- [ ] Search returns results for "Apple"
- [ ] Selecting a company fetches financial data
- [ ] Auto-populate fills all available fields
- [ ] Missing fields are clearly indicated
- [ ] User can manually edit auto-populated values
- [ ] Analysis works with auto-populated data
- [ ] Rate limiting prevents 429 errors
- [ ] Cache persists across app restarts
- [ ] Offline search works with cached tickers

---

## Dependencies

Already in `pubspec.yaml`:
- `dio: ^5.8.0+1` - HTTP client
- `hive: ^2.2.3` - Local storage
- `hive_flutter: ^1.1.0` - Hive Flutter bindings
- `provider: ^6.1.2` - State management

No new dependencies required.

---

## Continuation Notes

To continue this implementation:

1. Start with **Phase 1** - create the model and service files
2. Test the SEC API manually before building UI
3. The Python reference at `C:\Dev\Buffet_indicator\src\screener\sec_api.py` has the exact XBRL parsing logic
4. The main challenge is XBRL data format - different companies report differently

**Quick Start Command:**
```bash
cd C:\Dev\buffet-indicator-mobile
flutter pub get
flutter run
```
