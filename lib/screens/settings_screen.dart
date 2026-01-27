import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/financial_data.dart';
import '../providers/analysis_provider.dart';

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
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Investor Profile Section
              Text(
                'Investor Profile',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: InvestorProfile.all.map((profile) {
                    final isSelected =
                        provider.selectedProfile.name == profile.name;
                    return RadioListTile<InvestorProfile>(
                      value: profile,
                      groupValue: provider.selectedProfile,
                      onChanged: (value) {
                        if (value != null) {
                          provider.selectProfile(value);
                        }
                      },
                      title: Text(profile.name),
                      subtitle: Text(profile.description),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildThresholdRow(
                        context,
                        'Min FCF Yield',
                        '${provider.selectedProfile.minFcfYield}%',
                        Icons.attach_money,
                      ),
                      const Divider(),
                      _buildThresholdRow(
                        context,
                        'Min Operating Margin',
                        '${provider.selectedProfile.minOperatingMargin}%',
                        Icons.trending_up,
                      ),
                      const Divider(),
                      _buildThresholdRow(
                        context,
                        'Min Net Margin',
                        '${provider.selectedProfile.minNetMargin}%',
                        Icons.account_balance,
                      ),
                      const Divider(),
                      _buildThresholdRow(
                        context,
                        'Max Leverage',
                        '${provider.selectedProfile.maxLeverage}x',
                        Icons.balance,
                      ),
                    ],
                  ),
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
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Version'),
                      trailing: const Text('1.0.0'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.code),
                      title: const Text('Source Code'),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () {
                        // TODO: Open GitHub repo
                      },
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
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
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
