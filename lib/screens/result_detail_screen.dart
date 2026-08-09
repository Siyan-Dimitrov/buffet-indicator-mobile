import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart' show Share;

import '../models/financial_data.dart';
import '../utils/investor_content.dart';
import '../widgets/analysis_result_view.dart';

class ResultDetailScreen extends StatelessWidget {
  final AnalysisResult result;

  const ResultDetailScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved result'),
        actions: [
          IconButton(
            tooltip: 'Share result',
            onPressed: () => Share.share(
              InvestorContent.generateShareText(result),
            ),
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: AnalysisResultView(result: result),
          ),
        ),
      ),
    );
  }
}
