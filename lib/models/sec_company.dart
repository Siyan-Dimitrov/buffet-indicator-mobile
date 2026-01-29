import 'package:equatable/equatable.dart';

/// Represents a company from the SEC EDGAR database.
class SecCompany extends Equatable {
  final String cik;
  final String ticker;
  final String name;

  const SecCompany({
    required this.cik,
    required this.ticker,
    required this.name,
  });

  /// Parse from SEC company_tickers.json format.
  /// Each entry has: cik_str, ticker, title
  factory SecCompany.fromJson(Map<String, dynamic> json) {
    return SecCompany(
      cik: json['cik_str'].toString().padLeft(10, '0'),
      ticker: (json['ticker'] as String).toUpperCase(),
      name: json['title'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'cik_str': cik,
        'ticker': ticker,
        'title': name,
      };

  @override
  List<Object?> get props => [cik, ticker, name];
}
