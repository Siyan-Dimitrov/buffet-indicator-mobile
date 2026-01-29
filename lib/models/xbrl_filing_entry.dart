/// A single XBRL data point from an SEC filing.
///
/// Used to reason about filing periods for TTM calculation.
class XbrlFilingEntry {
  final double val;
  final String end;
  final String? start;
  final String form;
  final int fy;
  final String fp;

  const XbrlFilingEntry({
    required this.val,
    required this.end,
    this.start,
    required this.form,
    required this.fy,
    required this.fp,
  });

  factory XbrlFilingEntry.fromJson(Map<String, dynamic> json) {
    return XbrlFilingEntry(
      val: (json['val'] as num).toDouble(),
      end: json['end'] as String,
      start: json['start'] as String?,
      form: json['form'] as String,
      fy: json['fy'] as int,
      fp: json['fp'] as String,
    );
  }

  /// Duration of the reporting period in days. Null for instant (balance sheet) entries.
  int? get periodDays {
    if (start == null) return null;
    final s = DateTime.parse(start!);
    final e = DateTime.parse(end);
    return e.difference(s).inDays;
  }

  bool get isAnnual => form == '10-K' || fp == 'FY';

  bool get isQuarterly => form == '10-Q';

  /// True for balance sheet (point-in-time) entries that have no start date.
  bool get isInstant => start == null;

  /// True if this looks like a YTD cumulative figure (period > 100 days but < full year).
  bool get isYtdCumulative {
    final days = periodDays;
    if (days == null) return false;
    return days > 100 && days < 340;
  }

  /// True if this looks like a standalone quarter (~60-100 days).
  bool get isStandaloneQuarter {
    final days = periodDays;
    if (days == null) return false;
    return days >= 60 && days <= 100;
  }

  /// Numeric index for fiscal period quarter ordering.
  static int quarterIndex(String fp) {
    switch (fp) {
      case 'Q1':
        return 1;
      case 'Q2':
        return 2;
      case 'Q3':
        return 3;
      case 'Q4':
        return 4;
      default:
        return 0;
    }
  }
}
