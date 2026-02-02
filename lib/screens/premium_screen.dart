import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/premium_provider.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock Premium'),
      ),
      body: Consumer<PremiumProvider>(
        builder: (context, premium, _) {
          if (premium.isPremium) {
            return _buildAlreadyPremium(context);
          }
          return _buildUpgradeScreen(context, premium);
        },
      ),
    );
  }

  Widget _buildAlreadyPremium(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'You have Premium!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'All features are unlocked.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeScreen(BuildContext context, PremiumProvider premium) {
    final scheme = Theme.of(context).colorScheme;
    final price = premium.priceString ?? '\$0.99';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero
          Icon(
            Icons.workspace_premium,
            size: 64,
            color: scheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Upgrade to Premium',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'One-time purchase. Unlock everything forever.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),

          // Feature comparison
          _featureRow(context, 'Manual analysis', true, true),
          _featureRow(context, 'Buffett & Graham profiles', true, true),
          _featureRow(context, 'All 6 investor profiles', false, true),
          _featureRow(context, 'Ticker auto-lookup (SEC)', false, true),
          _featureRow(context, 'Compare All Investors', false, true),
          _featureRow(context, 'Full analysis history', false, true),
          _featureRow(context, 'Ad-free experience', false, true),

          const SizedBox(height: 32),

          // Error
          if (premium.error != null) ...[
            Card(
              color: scheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  premium.error!,
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Purchase button
          FilledButton.icon(
            onPressed: () => premium.purchase(),
            icon: const Icon(Icons.lock_open),
            label: Text('Unlock Premium — $price'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: Theme.of(context).textTheme.titleMedium,
            ),
          ),

          const SizedBox(height: 12),

          // Restore
          TextButton(
            onPressed: () => premium.restorePurchases(),
            child: const Text('Restore Purchases'),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(
    BuildContext context,
    String feature,
    bool free,
    bool premiumVal,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(feature),
          ),
          Expanded(
            child: Center(
              child: Icon(
                free ? Icons.check_circle : Icons.cancel,
                color: free ? Colors.green : Colors.red.shade300,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Icon(
                premiumVal ? Icons.check_circle : Icons.cancel,
                color: premiumVal ? Colors.green : Colors.red.shade300,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
