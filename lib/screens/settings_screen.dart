import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/financial_data.dart';
import '../providers/analysis_provider.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<AnalysisProvider>(
        builder: (context, provider, child) {
          final profile = provider.selectedProfile;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // Investor Profile Section
              Text(
                'Investor Profile',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: Column(
                  children: InvestorProfile.all.map((p) {
                    final isSelected = provider.selectedProfile.name == p.name;
                    return RadioListTile<InvestorProfile>(
                      value: p,
                      groupValue: provider.selectedProfile,
                      onChanged: (value) {
                        if (value != null) {
                          provider.selectProfile(value);
                        }
                      },
                      title: Text(p.name),
                      subtitle: Text(p.description),
                      secondary: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Current Thresholds Section
              Text(
                'Current Thresholds',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              // Profitability & Cash Flow
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: ExpansionTile(
                  title: const Text('Profitability & Cash Flow'),
                  leading: const Icon(Icons.trending_up),
                  initiallyExpanded: true,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          _buildThresholdRow(
                            context,
                            'FCF Yield',
                            '${profile.minFcfYield}%',
                            Icons.arrow_upward,
                            isMin: true,
                          ),
                          const Divider(),
                          _buildThresholdRow(
                            context,
                            'Operating Margin',
                            '${profile.minOperatingMargin}%',
                            Icons.arrow_upward,
                            isMin: true,
                          ),
                          const Divider(),
                          _buildThresholdRow(
                            context,
                            'Net Margin',
                            '${profile.minNetMargin}%',
                            Icons.arrow_upward,
                            isMin: true,
                          ),
                          const Divider(),
                          _buildThresholdRow(
                            context,
                            'Leverage',
                            '${profile.maxLeverage}x',
                            Icons.arrow_downward,
                            isMin: false,
                          ),
                          if (profile.minFcfToNetIncome != null) ...[
                            const Divider(),
                            _buildThresholdRow(
                              context,
                              'FCF/Net Income',
                              '${profile.minFcfToNetIncome}%',
                              Icons.arrow_upward,
                              isMin: true,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Valuation & Returns
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: ExpansionTile(
                  title: const Text('Valuation & Returns'),
                  leading: const Icon(Icons.assessment),
                  initiallyExpanded: false,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          if (profile.maxPeRatio != null)
                            _buildThresholdRow(
                              context,
                              'P/E Ratio',
                              '${profile.maxPeRatio}x',
                              Icons.arrow_downward,
                              isMin: false,
                            ),
                          if (profile.maxEvToEbitda != null) ...[
                            const Divider(),
                            _buildThresholdRow(
                              context,
                              'EV/EBITDA',
                              '${profile.maxEvToEbitda}x',
                              Icons.arrow_downward,
                              isMin: false,
                            ),
                          ],
                          if (profile.maxPToFcf != null) ...[
                            const Divider(),
                            _buildThresholdRow(
                              context,
                              'P/FCF',
                              '${profile.maxPToFcf}x',
                              Icons.arrow_downward,
                              isMin: false,
                            ),
                          ],
                          if (profile.maxPbRatio != null) ...[
                            const Divider(),
                            _buildThresholdRow(
                              context,
                              'P/B Ratio',
                              '${profile.maxPbRatio}x',
                              Icons.arrow_downward,
                              isMin: false,
                            ),
                          ],
                          if (profile.minRoic != null) ...[
                            const Divider(),
                            _buildThresholdRow(
                              context,
                              'ROIC',
                              '${profile.minRoic}%',
                              Icons.arrow_upward,
                              isMin: true,
                            ),
                          ],
                          if (profile.minRoe != null) ...[
                            const Divider(),
                            _buildThresholdRow(
                              context,
                              'ROE',
                              '${profile.minRoe}%',
                              Icons.arrow_upward,
                              isMin: true,
                            ),
                          ],
                          if (profile.maxPegRatio != null) ...[
                            const Divider(),
                            _buildThresholdRow(
                              context,
                              'PEG Ratio',
                              '${profile.maxPegRatio}x',
                              Icons.arrow_downward,
                              isMin: false,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // About Section
              Text(
                'About',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.school_outlined),
                      title: const Text('Show Tutorial'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('hasSeenOnboarding', false);
                        if (context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const OnboardingScreen(),
                            ),
                          );
                        }
                      },
                    ),
                    const Divider(height: 1),
                    const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Version'),
                      trailing: Text('1.0.0'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Licenses'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        showLicensePage(
                          context: context,
                          applicationName: 'Buffet Indicator',
                          applicationVersion: '1.0.0',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThresholdRow(
    BuildContext context,
    String label,
    String value,
    IconData directionIcon, {
    required bool isMin,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            directionIcon,
            size: 16,
            color: isMin
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.tertiary,
          ),
          const SizedBox(width: 8),
          Text(
            isMin ? 'Min' : 'Max',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
