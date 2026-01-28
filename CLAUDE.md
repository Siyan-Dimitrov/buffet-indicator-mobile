# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Buffet Indicator Mobile is a Flutter app for stock screening based on value investor criteria. Users input financial data for a company and receive letter grades (A-F) based on how well the company meets the thresholds of legendary investors (Buffett, Munger, Graham, Burry, Greenblatt, Lynch).

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Run tests
flutter test

# Run a single test file
flutter test test/analysis_test.dart

# Run tests matching a name pattern
flutter test --name "grades A when all criteria pass"

# Analyze code for issues
flutter analyze

# Build release APK
flutter build apk --release

# Clean and rebuild
flutter clean && flutter pub get
```

## Architecture

### State Management

Uses **Provider** pattern. `AnalysisProvider` is the single source of truth for:
- Selected investor profile
- Current analysis result
- Analysis history (capped at 50 entries)

### Data Flow

1. User enters financial inputs on `AnalyzeScreen`
2. `AnalysisProvider.analyze()` is called with `FinancialInputs`
3. `AnalysisService.analyze()` computes `DerivedMetrics` and evaluates against `InvestorProfile` thresholds
4. Returns `AnalysisResult` with grade, score, criteria results, and prescriptions

### Key Models (`lib/models/financial_data.dart`)

- `FinancialInputs`: Raw financial data (revenue, FCF, market cap, debt, EBITDA, etc.)
- `DerivedMetrics`: Calculated metrics (FCF Yield %, Operating Margin %, Net Margin %, Leverage ratio)
- `InvestorProfile`: Threshold configuration for each investor (6 predefined profiles with static constants)
- `AnalysisResult`: Complete analysis output including grade, passing criteria, and improvement prescriptions
- `CriterionResult`: Pass/fail status for individual metrics against thresholds

### Grading Logic (`lib/services/analysis_service.dart`)

Score is calculated as percentage of 4 criteria passed:
- 100% (4/4) = A
- 75% (3/4) = B
- 50% (2/4) = C
- 25% (1/4) = D
- 0% (0/4) = F

Prescriptions are generated for failing criteria with specific dollar amounts needed to meet thresholds.

### Local Storage

Hive is initialized in `main.dart` but persistence is not yet fully implemented (see ROADMAP.md Phase 2).

## Tech Stack

- Flutter 3.24+ with Dart SDK >=3.0.0 <4.0.0
- State: Provider
- Local storage: Hive (setup ready, persistence pending)
- HTTP: Dio (for future API integration)
- Charts: fl_chart (for future visualizations)

## Active Development Plans

### SEC EDGAR API Integration (Next Up)

See **`SEC_API_IMPLEMENTATION_PLAN.md`** for detailed implementation plan.

This will add:
- Ticker search with autocomplete
- Auto-populate financial data from SEC filings
- Local ticker cache (13,000+ companies)

Reference implementation: `C:\Dev\Buffet_indicator\src\screener\sec_api.py`
