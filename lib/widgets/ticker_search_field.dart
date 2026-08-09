import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sec_company.dart';
import '../providers/sec_provider.dart';

/// A debounced search field with dropdown results for SEC company tickers.
class TickerSearchField extends StatefulWidget {
  final void Function(SecCompany company)? onCompanySelected;

  const TickerSearchField({super.key, this.onCompanySelected});

  @override
  State<TickerSearchField> createState() => _TickerSearchFieldState();
}

class _TickerSearchFieldState extends State<TickerSearchField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _showResults = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _showResults = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _showResults = query.trim().isNotEmpty;
      _hasSearched = false;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<SecProvider>().searchCompanies(query);
      if (mounted) setState(() => _hasSearched = true);
    });
  }

  void _onCompanyTapped(SecCompany company) {
    _controller.text = company.ticker;
    setState(() => _showResults = false);
    context.read<SecProvider>().selectCompany(company);
    widget.onCompanySelected?.call(company);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SecProvider>(
      builder: (context, provider, _) {
        final isCacheLoading = provider.isCacheLoading;
        final tickerCount = provider.tickerCount;
        final cacheError = provider.error != null &&
            isCacheLoading == false &&
            tickerCount == 0;

        String hintText;
        if (isCacheLoading) {
          hintText = 'Preparing company search…';
        } else if (tickerCount > 0) {
          hintText = 'Search ${_formatCount(tickerCount)} companies';
        } else {
          hintText = 'Try AAPL, MSFT, or Apple';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: !isCacheLoading,
              decoration: InputDecoration(
                labelText: 'Ticker or company name',
                hintText: hintText,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _buildSuffixIcon(provider),
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
            ),

            // Loading indicator
            if (isCacheLoading)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: LinearProgressIndicator(),
              ),

            // Cache error with retry
            if (cacheError) ...[
              const SizedBox(height: 4),
              InkWell(
                onTap: () => provider.refreshTickerCache(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Failed to load — Tap to retry',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Search results dropdown
            if (_showResults && !isCacheLoading)
              Builder(
                builder: (context) {
                  if (provider.searchResults.isEmpty) {
                    if (!_hasSearched) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(4, 10, 4, 2),
                      child: Text(
                        'No matching SEC-listed companies found.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }
                  return Card(
                    margin: const EdgeInsets.only(top: 4),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: provider.searchResults.length,
                        itemBuilder: (context, index) {
                          final company = provider.searchResults[index];
                          return ListTile(
                            dense: true,
                            title: Text(
                              company.ticker,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              company.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _onCompanyTapped(company),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildSuffixIcon(SecProvider provider) {
    if (provider.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_controller.text.isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          _controller.clear();
          setState(() => _showResults = false);
          context.read<SecProvider>().clearSelection();
        },
      );
    }
    return const SizedBox.shrink();
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(0)},000+';
    }
    return '$count';
  }
}
