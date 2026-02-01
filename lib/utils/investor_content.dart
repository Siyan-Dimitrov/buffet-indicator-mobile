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

  /// General metric descriptions — what each metric is and why it matters
  static const Map<String, String> metricDescriptions = {
    'FCF Yield':
        'Free Cash Flow Yield measures the cash a company generates relative to its market cap. '
        'A higher yield means you\'re paying less for each dollar of real cash the business produces.',
    'Operating Margin':
        'Operating Margin is the percentage of revenue left after covering operating expenses. '
        'A wide margin signals competitive advantage and efficient operations.',
    'Net Margin':
        'Net Margin is the percentage of revenue that becomes profit after all expenses, taxes, and interest. '
        'It reflects overall profitability and pricing power.',
    'Leverage':
        'Leverage (Net Debt / EBITDA) measures how many years of earnings it would take to pay off debt. '
        'Lower leverage means less financial risk and more flexibility during downturns.',
    'P/E Ratio':
        'Price-to-Earnings Ratio measures how much investors pay per dollar of earnings. '
        'A lower P/E can indicate undervaluation, while a very high P/E may signal overpricing.',
    'EV/EBITDA':
        'Enterprise Value to EBITDA compares the total value of a business (including debt) to its operating earnings. '
        'It\'s often more accurate than P/E for comparing companies with different capital structures.',
    'P/FCF':
        'Price-to-Free-Cash-Flow measures the price you pay per dollar of actual cash generated. '
        'Unlike P/E, it focuses on real cash rather than accounting earnings, making it harder to manipulate.',
    'P/B Ratio':
        'Price-to-Book Ratio compares a company\'s market price to its net asset value. '
        'A low P/B can indicate undervaluation or provide a floor on downside risk.',
    'ROIC':
        'Return on Invested Capital measures how efficiently a company turns capital into profits. '
        'A high ROIC indicates strong competitive advantages and smart capital allocation.',
    'ROE':
        'Return on Equity measures how much profit a company generates for each dollar of shareholder equity. '
        'It shows how well management creates value for shareholders.',
    'FCF/Net Income':
        'FCF-to-Net-Income ratio measures earnings quality — what percentage of reported profits is backed by real cash. '
        'A ratio above 80% suggests reliable, high-quality earnings.',
    'PEG Ratio':
        'The PEG Ratio divides P/E by the earnings growth rate, adjusting valuation for growth. '
        'A PEG below 1.0 suggests you\'re getting growth at a bargain price.',
  };

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
      'P/E Ratio':
          'Buffett wants a reasonable earnings multiple — he\'ll pay up for quality, but not excessively.',
      'EV/EBITDA':
          'Buffett checks enterprise value to ensure the whole business isn\'t overpriced.',
      'P/FCF':
          'Buffett focuses on price relative to actual cash generation, not just accounting earnings.',
      'P/B Ratio':
          'Buffett is flexible on book value — great businesses often trade above book.',
      'ROIC':
          'High return on invested capital proves a durable moat — Buffett\'s core test.',
      'ROE':
          'Buffett expects strong returns on equity as proof of management quality.',
      'FCF/Net Income':
          'Buffett wants earnings backed by real cash — high conversion signals quality.',
      'PEG Ratio':
          'Buffett considers growth-adjusted value, though it\'s not his primary focus.',
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
      'P/E Ratio':
          'Munger will pay a fair P/E for a wonderful company, but not an excessive one.',
      'EV/EBITDA':
          'Munger uses enterprise value multiples as a sanity check on overall valuation.',
      'P/FCF':
          'Munger considers price-to-cash-flow a better indicator than P/E for quality businesses.',
      'P/B Ratio':
          'Munger cares less about book value — he\'d rather own a great business at a fair price.',
      'ROIC':
          'Munger demands high returns on capital — the hallmark of a truly great business.',
      'ROE':
          'Munger seeks businesses that earn exceptional returns on shareholder equity.',
      'FCF/Net Income':
          'Munger wants to see earnings translated into real cash flow, not just paper profits.',
      'PEG Ratio':
          'Munger weighs growth-adjusted price, preferring quality over pure cheapness.',
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
      'P/E Ratio':
          'Graham\'s classic screen demands a low P/E — paying less than 15x earnings is key.',
      'EV/EBITDA':
          'Graham looks at enterprise value multiples to ensure the entire business is cheap.',
      'P/FCF':
          'Graham wants to pay a low multiple of cash flow for maximum margin of safety.',
      'P/B Ratio':
          'Graham\'s famous rule: never pay more than 1.5x book value for margin of safety.',
      'ROIC':
          'Graham checks return on capital to ensure the business is fundamentally sound.',
      'ROE':
          'Graham uses return on equity as a minimum quality bar for defensive investors.',
      'FCF/Net Income':
          'Graham values cash earnings — high FCF conversion reduces accounting risk.',
      'PEG Ratio':
          'Graham applies the PEG ratio to ensure growth doesn\'t come at an unreasonable price.',
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
      'P/E Ratio':
          'Burry demands a very low P/E — his contrarian bets require extreme cheapness.',
      'EV/EBITDA':
          'Burry uses EV/EBITDA to find companies that are cheap on an enterprise basis.',
      'P/FCF':
          'Burry focuses on cash flow multiples — he wants to buy actual dollars cheaply.',
      'P/B Ratio':
          'Burry looks for stocks trading near or below book value as a floor on downside.',
      'ROIC':
          'Burry checks capital returns to distinguish cheap quality from value traps.',
      'ROE':
          'Burry uses ROE to verify the business can earn its way out of a downturn.',
      'FCF/Net Income':
          'Burry values cash backing — he wants to see real cash behind reported earnings.',
      'PEG Ratio':
          'Burry demands extreme cheapness relative to any growth — a low PEG confirms deep value.',
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
      'P/E Ratio':
          'Greenblatt uses P/E alongside his formula to confirm earnings aren\'t overpriced.',
      'EV/EBITDA':
          'Greenblatt uses EV/EBITDA as a key measure of earnings yield in his magic formula.',
      'P/FCF':
          'Greenblatt values cash flow multiples as a cross-check on his earnings yield ranking.',
      'P/B Ratio':
          'Greenblatt considers book value as a secondary check on asset-heavy businesses.',
      'ROIC':
          'ROIC is the other half of Greenblatt\'s magic formula — high returns on capital deployed.',
      'ROE':
          'Greenblatt expects strong ROE as confirmation of high capital efficiency.',
      'FCF/Net Income':
          'Greenblatt wants earnings quality — real cash flow should back accounting profits.',
      'PEG Ratio':
          'Greenblatt checks growth-adjusted valuation to avoid overpaying for high-return businesses.',
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
      'P/E Ratio':
          'Lynch compares P/E to growth rate — a P/E below the growth rate is ideal.',
      'EV/EBITDA':
          'Lynch uses enterprise value multiples as a secondary valuation sanity check.',
      'P/FCF':
          'Lynch considers cash flow multiples, especially for capital-intensive businesses.',
      'P/B Ratio':
          'Lynch checks book value for asset plays and turnaround situations.',
      'ROIC':
          'Lynch uses return on capital to distinguish great growers from mediocre ones.',
      'ROE':
          'Lynch looks for companies that earn solid returns on equity as a quality signal.',
      'FCF/Net Income':
          'Lynch wants to see real cash generation, not just paper earnings from fast growers.',
      'PEG Ratio':
          'The PEG ratio is Lynch\'s signature metric — growth should justify the P/E paid.',
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
