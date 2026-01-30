import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/financial_data.dart';
import '../services/analysis_service.dart';

/// Provider for managing analysis state
class AnalysisProvider extends ChangeNotifier {
  final AnalysisService _analysisService = AnalysisService();
  final Box<String> _historyBox;

  InvestorProfile _selectedProfile = InvestorProfile.buffett;
  AnalysisResult? _currentResult;
  List<AnalysisResult> _history = [];
  List<AnalysisResult>? _comparisonResults;
  bool _isLoading = false;
  String? _error;

  // Getters
  InvestorProfile get selectedProfile => _selectedProfile;
  AnalysisResult? get currentResult => _currentResult;
  List<AnalysisResult> get history => List.unmodifiable(_history);
  List<AnalysisResult>? get comparisonResults =>
      _comparisonResults != null ? List.unmodifiable(_comparisonResults!) : null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AnalysisProvider({required Box<String> historyBox})
      : _historyBox = historyBox {
    _loadHistory();
  }

  void _loadHistory() {
    try {
      _history = _historyBox.values
          .map((json) => AnalysisResult.fromJsonString(json))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      debugPrint('Failed to load history: $e');
      _history = [];
    }
  }

  Future<void> _saveHistory() async {
    try {
      await _historyBox.clear();
      // Store in reverse so newest is last in box (we reverse on load)
      for (final result in _history.reversed) {
        await _historyBox.add(result.toJsonString());
      }
    } catch (e) {
      debugPrint('Failed to save history: $e');
    }
  }

  /// Change the selected investor profile
  void selectProfile(InvestorProfile profile) {
    _selectedProfile = profile;
    notifyListeners();
  }

  /// Perform analysis on financial inputs
  Future<void> analyze(FinancialInputs inputs) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate network delay for realistic UX
      await Future.delayed(const Duration(milliseconds: 300));

      _currentResult = _analysisService.analyze(inputs, _selectedProfile);
      _history.insert(0, _currentResult!);

      // Keep only last 50 analyses
      if (_history.length > 50) {
        _history = _history.sublist(0, 50);
      }

      await _saveHistory();
    } catch (e) {
      _error = 'Analysis failed. Please check your inputs and try again.';
      debugPrint('Analysis error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Run analysis against all 6 investor profiles
  Future<void> compareAll(FinancialInputs inputs) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      _comparisonResults = _analysisService.analyzeAll(inputs);
    } catch (e) {
      _error = 'Comparison failed. Please check your inputs and try again.';
      debugPrint('Comparison error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear comparison results
  void clearComparison() {
    _comparisonResults = null;
    notifyListeners();
  }

  /// Clear current analysis result
  void clearResult() {
    _currentResult = null;
    _comparisonResults = null;
    _error = null;
    notifyListeners();
  }

  /// Clear analysis history
  void clearHistory() {
    _history.clear();
    _saveHistory();
    notifyListeners();
  }

  /// Remove a specific result from history
  void removeFromHistory(int index) {
    if (index >= 0 && index < _history.length) {
      _history.removeAt(index);
      _saveHistory();
      notifyListeners();
    }
  }
}
