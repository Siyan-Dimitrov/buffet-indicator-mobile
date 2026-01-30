import 'package:flutter/foundation.dart';

import '../models/financial_data.dart';
import '../services/analysis_service.dart';

/// Provider for managing analysis state
class AnalysisProvider extends ChangeNotifier {
  final AnalysisService _analysisService = AnalysisService();

  InvestorProfile _selectedProfile = InvestorProfile.buffett;
  AnalysisResult? _currentResult;
  List<AnalysisResult> _history = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  InvestorProfile get selectedProfile => _selectedProfile;
  AnalysisResult? get currentResult => _currentResult;
  List<AnalysisResult> get history => List.unmodifiable(_history);
  bool get isLoading => _isLoading;
  String? get error => _error;

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
    } catch (e) {
      _error = 'Analysis failed. Please check your inputs and try again.';
      debugPrint('Analysis error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear current analysis result
  void clearResult() {
    _currentResult = null;
    _error = null;
    notifyListeners();
  }

  /// Clear analysis history
  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  /// Remove a specific result from history
  void removeFromHistory(int index) {
    if (index >= 0 && index < _history.length) {
      _history.removeAt(index);
      notifyListeners();
    }
  }
}
