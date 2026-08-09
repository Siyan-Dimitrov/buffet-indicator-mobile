import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart' show Share;

import '../models/financial_data.dart';
import '../providers/analysis_provider.dart';
import '../utils/investor_content.dart';
import '../utils/theme.dart';
import 'result_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  final VoidCallback? onAnalyzeTap;

  const HistoryScreen({super.key, this.onAnalyzeTap});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedGrade = 'All';

  static const _gradeFilters = ['All', 'A', 'B', 'C', 'D', 'F'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AnalysisResult> _filterResults(List<AnalysisResult> history) {
    return history.where((result) {
      // Grade filter
      if (_selectedGrade != 'All' && result.grade != _selectedGrade) {
        return false;
      }
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName =
            result.inputs.companyName.toLowerCase().contains(query);
        final matchesTicker =
            result.inputs.ticker.toLowerCase().contains(query);
        if (!matchesName && !matchesTicker) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved results'),
        actions: [
          Consumer<AnalysisProvider>(
            builder: (context, provider, child) {
              if (provider.history.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'Clear saved results',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear saved results?'),
                      content: const Text(
                        'This removes every saved screening result from this device.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () {
                            provider.clearHistory();
                            Navigator.pop(context);
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<AnalysisProvider>(
        builder: (context, provider, child) {
          if (provider.history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved results yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: widget.onAnalyzeTap,
                    icon: const Icon(Icons.search),
                    label: const Text('Screen a stock'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Analyze a company to see it here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            );
          }

          final filtered = _filterResults(provider.history);

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or ticker',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),

              // Grade filter chips
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _gradeFilters.map((grade) {
                    final isSelected = _selectedGrade == grade;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(grade),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _selectedGrade = grade);
                        },
                        backgroundColor: grade != 'All'
                            ? AppTheme.getGradeColor(
                                grade,
                                Theme.of(context).brightness,
                              ).withOpacity(0.1)
                            : null,
                        selectedColor: grade != 'All'
                            ? AppTheme.getGradeColor(
                                grade,
                                Theme.of(context).brightness,
                              ).withOpacity(0.3)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Results list or empty state
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No matching results',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final result = filtered[index];
                          final gradeColor = AppTheme.getGradeColor(
                            result.grade,
                            Theme.of(context).brightness,
                          );

                          return Dismissible(
                            key: Key(
                                '${result.inputs.ticker}_${result.analyzedAt}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              color: Theme.of(context).colorScheme.error,
                              child: Icon(
                                Icons.delete,
                                color: Theme.of(context).colorScheme.onError,
                              ),
                            ),
                            onDismissed: (_) {
                              // Find original index in full history
                              final originalIndex =
                                  provider.history.indexOf(result);
                              if (originalIndex >= 0) {
                                provider.removeFromHistory(originalIndex);
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${result.inputs.ticker} removed from saved results',
                                      ),
                                      action: SnackBarAction(
                                        label: 'Undo',
                                        onPressed: () =>
                                            provider.restoreToHistory(
                                          originalIndex,
                                          result,
                                        ),
                                      ),
                                    ),
                                  );
                              }
                            },
                            child: Card(
                              elevation: 0,
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLow,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: gradeColor,
                                      width: 4,
                                    ),
                                  ),
                                ),
                                child: ListTile(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ResultDetailScreen(result: result),
                                      ),
                                    );
                                  },
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: gradeColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        result.grade,
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: gradeColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(result.inputs.companyName),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${result.inputs.ticker} - ${result.profile.name}',
                                      ),
                                      Text(
                                        _formatDate(result.analyzedAt),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${result.score}%',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: gradeColor,
                                            ),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(Icons.share, size: 18),
                                        tooltip: 'Share',
                                        onPressed: () {
                                          final text =
                                              InvestorContent.generateShareText(
                                                  result);
                                          Share.share(text);
                                        },
                                      ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final diff = today.difference(dateOnly).inDays;

    final time = TimeOfDay.fromDateTime(date).format(context);
    if (diff == 0) return 'Today, $time';
    if (diff == 1) return 'Yesterday, $time';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final year = date.year == now.year ? '' : ' ${date.year}';
    return '${months[date.month - 1]} ${date.day}$year, $time';
  }
}
