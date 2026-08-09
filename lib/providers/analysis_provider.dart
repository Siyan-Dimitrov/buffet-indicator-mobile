import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/financial_data.dart';
import '../services/analysis_service.dart';

/// Provider for managing analysis state
class AnalysisProvider extends ChangeNotifier {
  final AnalysisService _analysisService = AnalysisService();
  final Box<String> _historyBox;
  final SharedPreferences? _preferences;

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
  List<AnalysisResult>? get comparisonResults => _comparisonResults != null
      ? List.unmodifiable(_comparisonResults!)
      : null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AnalysisProvider({
    required Box<String> historyBox,
    SharedPreferences? preferences,
  })  : _historyBox = historyBox,
        _preferences = preferences {
    _loadHistory();
    _loadSelectedProfile();
  }

  void _loadSelectedProfile() {
    final savedName = _preferences?.getString('selectedInvestorProfile');
    if (savedName == null) return;

    for (final profile in InvestorProfile.all) {
      if (profile.name == savedName) {
        _selectedProfile = profile;
        return;
      }
    }
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
    if (_selectedProfile == profile) return;
    _selectedProfile = profile;
    _preferences?.setString('selectedInvestorProfile', profile.name);
    _currentResult = null;
    _comparisonResults = null;
    _error = null;
    notifyListeners();
  }

  /// Perform analysis on financial inputs
  Future<void> analyze(FinancialInputs inputs) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentResult = _analysisService.analyze(inputs, _selectedProfile);
      _comparisonResults = null;
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
      _comparisonResults = _analysisService.analyzeAll(inputs);
      _currentResult = null;
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

  /// Restore a history item, used by the delete undo affordance.
  void restoreToHistory(int index, AnalysisResult result) {
    final safeIndex = index.clamp(0, _history.length);
    _history.insert(safeIndex, result);
    if (_history.length > 50) {
      _history = _history.sublist(0, 50);
    }
    _saveHistory();
    notifyListeners();
  }
}
