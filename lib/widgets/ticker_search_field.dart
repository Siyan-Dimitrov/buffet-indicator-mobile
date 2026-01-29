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
    setState(() => _showResults = query.isNotEmpty);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<SecProvider>().searchCompanies(query);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: 'Search Ticker',
            hintText: 'e.g., AAPL, MSFT, or Apple',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: Consumer<SecProvider>(
              builder: (context, provider, _) {
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
              },
            ),
            border: const OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
          onChanged: _onSearchChanged,
        ),
        if (_showResults)
          Consumer<SecProvider>(
            builder: (context, provider, _) {
              if (provider.searchResults.isEmpty) {
                return const SizedBox.shrink();
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
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
  }
}
