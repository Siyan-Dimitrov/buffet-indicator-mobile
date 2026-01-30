import '../models/financial_data.dart';

/// Grade-to-verdict sentences per investor
class InvestorContent {
  static String getVerdict(InvestorProfile profile, String grade, String companyName) {
    final firstName = profile.name.split(' ').first;
    final lastName = profile.name.split(' ').last;

    switch (grade) {
      case 'A':
        return _positiveVerdict(profile.name, companyName);
      case 'B':
        return _leanPositiveVerdict(profile.name, companyName);
      case 'C':
        return _cautiousVerdict(firstName, lastName, companyName);
      case 'D':
        return _leanNegativeVerdict(firstName, lastName, companyName);
      case 'F':
      default:
        return _negativeVerdict(profile.name, companyName);
    }
  }

  static String _positiveVerdict(String name, String company) {
    final verdicts = {
      'Warren Buffett':
          '$name would likely invest in $company — a quality business with strong fundamentals.',
      'Charlie Munger':
          '$name would approve of $company — quality at a fair price.',
      'Benjamin Graham':
          '$name would see $company as a sound investment with ample margin of safety.',
      'Michael Burry':
          '$name would see deep value in $company — the numbers strongly support this pick.',
      'Joel Greenblatt':
          '$name\'s magic formula ranks $company highly — strong returns at a low price.',
      'Peter Lynch':
          '$name would call $company a great GARP pick — growth at a very reasonable price.',
    };
    return verdicts[name] ?? '$name would likely invest in $company.';
  }

  static String _leanPositiveVerdict(String name, String company) {
    final verdicts = {
      'Warren Buffett':
          '$name would likely consider $company — solid fundamentals with minor concerns.',
      'Charlie Munger':
          '$name would find $company mostly attractive, though not perfect.',
      'Benjamin Graham':
          '$name would see reasonable value in $company, with some room for improvement.',
      'Michael Burry':
          '$name would find $company interesting — good value with slight reservations.',
      'Joel Greenblatt':
          '$name\'s formula shows $company is promising, with one area to watch.',
      'Peter Lynch':
          '$name would see $company as a decent GARP candidate worth monitoring.',
    };
    return verdicts[name] ?? '$name would likely consider $company.';
  }

  static String _cautiousVerdict(
      String firstName, String lastName, String company) {
    return '$firstName $lastName would be cautious about $company — mixed signals across key metrics.';
  }

  static String _leanNegativeVerdict(
      String firstName, String lastName, String company) {
    return '$firstName $lastName would likely pass on $company — too few criteria met.';
  }

  static String _negativeVerdict(String name, String company) {
    final verdicts = {
      'Warren Buffett':
          '$name would pass on $company — it doesn\'t meet his quality standards.',
      'Charlie Munger':
          '$name would say $company is "not even close" to his requirements.',
      'Benjamin Graham':
          '$name would see no margin of safety in $company at current levels.',
      'Michael Burry':
          '$name would not find deep value in $company — the numbers don\'t add up.',
      'Joel Greenblatt':
          '$name\'s magic formula would rank $company poorly — avoid.',
      'Peter Lynch':
          '$name would skip $company — neither growth nor value is compelling here.',
    };
    return verdicts[name] ?? '$name would likely pass on $company.';
  }

  /// Investor-specific commentary per metric
  static String? getMetricCommentary(
      InvestorProfile profile, String metricName) {
    final commentaries = _metricCommentaries[profile.name];
    if (commentaries == null) return null;
    return commentaries[metricName];
  }

  static const Map<String, Map<String, String>> _metricCommentaries = {
    'Warren Buffett': {
      'FCF Yield':
          'Buffett prizes companies that generate abundant free cash flow relative to their price.',
      'Operating Margin':
          'A wide operating margin signals the durable competitive advantage Buffett seeks.',
      'Net Margin':
          'High net margins indicate pricing power — a hallmark of Buffett\'s "moat" companies.',
      'Leverage':
          'Buffett prefers companies that can fund growth without excessive debt.',
    },
    'Charlie Munger': {
      'FCF Yield':
          'Munger will pay a fair price, but still demands solid cash flow generation.',
      'Operating Margin':
          'Munger insists on wide operating margins as proof of a great business.',
      'Net Margin':
          'High net margins reflect the quality businesses Munger admires most.',
      'Leverage':
          'Munger is stricter on leverage — a conservative balance sheet is essential.',
    },
    'Benjamin Graham': {
      'FCF Yield':
          'Graham demands a high FCF yield — his margin of safety starts with price.',
      'Operating Margin':
          'Graham is more forgiving on margins if the price is cheap enough.',
      'Net Margin':
          'Minimal profitability is required, but Graham focuses more on valuation.',
      'Leverage':
          'Graham insists on low leverage — a fortress balance sheet protects against loss.',
    },
    'Michael Burry': {
      'FCF Yield':
          'Burry hunts for the highest FCF yields — deep value is non-negotiable.',
      'Operating Margin':
          'Burry tolerates lower margins if the company is dramatically undervalued.',
      'Net Margin':
          'Minimal profitability is fine for Burry if the stock is dirt cheap.',
      'Leverage':
          'Burry accepts moderate leverage in contrarian plays — risk is part of the thesis.',
    },
    'Joel Greenblatt': {
      'FCF Yield':
          'Greenblatt\'s formula rewards companies with strong earnings yield.',
      'Operating Margin':
          'A high operating margin is half of Greenblatt\'s magic formula.',
      'Net Margin':
          'Strong net margins confirm the business earns high returns on capital.',
      'Leverage':
          'Greenblatt prefers manageable debt to keep the formula\'s edge intact.',
    },
    'Peter Lynch': {
      'FCF Yield':
          'Lynch is flexible on yield — he\'ll accept less if growth is strong.',
      'Operating Margin':
          'Lynch wants decent margins but weighs them against growth potential.',
      'Net Margin':
          'Healthy net margins matter to Lynch, especially for "stalwart" companies.',
      'Leverage':
          'Lynch tolerates higher leverage for fast growers, but prefers moderation.',
    },
  };

  /// Generate a plain-text summary for sharing
  static String generateShareText(AnalysisResult result) {
    final buffer = StringBuffer();
    buffer.writeln('📊 Buffet Indicator Analysis');
    buffer.writeln('═══════════════════════════');
    buffer.writeln();
    buffer.writeln(
        '${result.inputs.companyName} (${result.inputs.ticker})');
    buffer.writeln('Investor: ${result.profile.name}');
    buffer.writeln('Grade: ${result.grade} (${result.score}%)');
    buffer.writeln();

    buffer.writeln('Metrics:');
    for (final c in result.criteria) {
      final icon = c.passed ? '✅' : '❌';
      final label = c.isMaximum ? 'Max' : 'Min';
      buffer.writeln(
          '$icon ${c.name}: ${c.actualValue.toStringAsFixed(2)}${c.unit} ($label: ${c.threshold.toStringAsFixed(2)}${c.unit})');
    }

    if (result.prescriptions.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Prescriptions:');
      for (final p in result.prescriptions) {
        buffer.writeln('• $p');
      }
    }

    buffer.writeln();
    buffer.writeln(getVerdict(result.profile, result.grade,
        result.inputs.companyName));

    buffer.writeln();
    buffer.writeln('— Buffet Indicator App');

    return buffer.toString();
  }
}
