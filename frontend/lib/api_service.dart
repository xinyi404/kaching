import 'dart:convert';

import 'package:http/http.dart' as http;

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);

class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.amount,
    required this.type,
    required this.currency,
    required this.category,
    required this.occurredAt,
    this.merchant,
    this.description,
  });

  final int id;
  final double amount;
  final String type;
  final String currency;
  final String category;
  final DateTime occurredAt;
  final String? merchant;
  final String? description;

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    return TransactionRecord(
      id: json['id'] as int,
      amount: double.parse(json['amount'].toString()),
      type: json['transaction_type'] as String,
      currency: json['currency'] as String,
      category: json['category'] as String? ?? 'Other',
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      merchant: json['merchant'] as String?,
      description: json['description'] as String?,
    );
  }
}

class StatementTransactionItem {
  const StatementTransactionItem({
    required this.amount,
    required this.type,
    required this.currency,
    required this.category,
    required this.occurredAt,
    required this.isDuplicate,
    this.id,
    this.merchant,
    this.description,
  });

  final int? id;
  final double amount;
  final String type;
  final String currency;
  final String category;
  final DateTime occurredAt;
  final bool isDuplicate;
  final String? merchant;
  final String? description;

  factory StatementTransactionItem.fromJson(Map<String, dynamic> json) {
    return StatementTransactionItem(
      id: json['id'] as int?,
      amount: double.parse(json['amount'].toString()),
      type: json['transaction_type'] as String,
      currency: json['currency'] as String,
      category: json['category'] as String? ?? 'Other',
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      isDuplicate: json['is_duplicate'] as bool? ?? false,
      merchant: json['merchant'] as String?,
      description: json['description'] as String?,
    );
  }
}

class StatementFileSummary {
  const StatementFileSummary({
    required this.filename,
    required this.totalExtracted,
    required this.totalSaved,
    required this.duplicatesSkipped,
    required this.totalIncome,
    required this.totalExpense,
    this.institutionName,
    this.statementPeriod,
    this.error,
  });

  final String filename;
  final String? institutionName;
  final String? statementPeriod;
  final int totalExtracted;
  final int totalSaved;
  final int duplicatesSkipped;
  final double totalIncome;
  final double totalExpense;
  final String? error;

  factory StatementFileSummary.fromJson(Map<String, dynamic> json) {
    return StatementFileSummary(
      filename: json['filename'] as String? ?? '',
      institutionName: json['institution_name'] as String?,
      statementPeriod: json['statement_period'] as String?,
      totalExtracted: json['total_extracted'] as int? ?? 0,
      totalSaved: json['total_saved'] as int? ?? 0,
      duplicatesSkipped: json['duplicates_skipped'] as int? ?? 0,
      totalIncome: double.parse((json['total_income'] ?? 0).toString()),
      totalExpense: double.parse((json['total_expense'] ?? 0).toString()),
      error: json['error'] as String?,
    );
  }
}

class StatementUploadResponse {
  const StatementUploadResponse({
    required this.filename,
    required this.currency,
    required this.totalExtracted,
    required this.totalSaved,
    required this.duplicatesSkipped,
    required this.totalIncome,
    required this.totalExpense,
    required this.transactions,
    this.totalFiles = 1,
    this.fileSummaries = const [],
    this.institutionName,
    this.statementPeriod,
    this.accountIdentifier,
  });

  final String filename;
  final int totalFiles;
  final String? institutionName;
  final String? statementPeriod;
  final String? accountIdentifier;
  final String currency;
  final int totalExtracted;
  final int totalSaved;
  final int duplicatesSkipped;
  final double totalIncome;
  final double totalExpense;
  final List<StatementFileSummary> fileSummaries;
  final List<StatementTransactionItem> transactions;

  factory StatementUploadResponse.fromJson(Map<String, dynamic> json) {
    final txList = (json['transactions'] as List<dynamic>? ?? [])
        .map((e) => StatementTransactionItem.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    final summaryList = (json['file_summaries'] as List<dynamic>? ?? [])
        .map((e) => StatementFileSummary.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    return StatementUploadResponse(
      filename: json['filename'] as String? ?? '',
      totalFiles: json['total_files'] as int? ?? 1,
      institutionName: json['institution_name'] as String?,
      statementPeriod: json['statement_period'] as String?,
      accountIdentifier: json['account_identifier'] as String?,
      currency: json['currency'] as String? ?? 'MYR',
      totalExtracted: json['total_extracted'] as int? ?? 0,
      totalSaved: json['total_saved'] as int? ?? 0,
      duplicatesSkipped: json['duplicates_skipped'] as int? ?? 0,
      totalIncome: double.parse((json['total_income'] ?? 0).toString()),
      totalExpense: double.parse((json['total_expense'] ?? 0).toString()),
      fileSummaries: summaryList,
      transactions: txList,
    );
  }
}

class FinanceApi {
  FinanceApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  void close() => _client.close();

  Future<List<TransactionRecord>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) {
      queryParams['start_date'] = _formatDateTimeForApi(startDate);
    }
    if (endDate != null) {
      queryParams['end_date'] = _formatDateTimeForApi(endDate);
    }
    final baseUri = Uri.parse('$apiBaseUrl/api/v1/transactions');
    final uri = queryParams.isEmpty
        ? baseUri
        : baseUri.replace(queryParameters: queryParams);

    final response = await _client.get(uri).timeout(const Duration(seconds: 15));
    _checkResponse(response);
    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .map((item) => TransactionRecord.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> createTransaction({
    required double amount,
    required String type,
    required String currency,
    required String category,
    required DateTime occurredAt,
    String? merchant,
    String? description,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$apiBaseUrl/api/v1/transactions'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'amount': amount.toStringAsFixed(2),
            'transaction_type': type,
            'currency': currency,
            'category': category,
            'merchant': merchant,
            'description': description,
            'source': 'manual',
            'occurred_at': _formatDateTimeForApi(occurredAt),
          }),
        )
        .timeout(const Duration(seconds: 15));
    _checkResponse(response);
  }

  Future<void> updateTransaction({
    required int id,
    required double amount,
    required String type,
    required String currency,
    required String category,
    required DateTime occurredAt,
    String? merchant,
    String? description,
  }) async {
    final response = await _client
        .put(
          Uri.parse('$apiBaseUrl/api/v1/transactions/$id'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'amount': amount.toStringAsFixed(2),
            'transaction_type': type,
            'currency': currency,
            'category': category,
            'merchant': merchant,
            'description': description,
            'occurred_at': _formatDateTimeForApi(occurredAt),
          }),
        )
        .timeout(const Duration(seconds: 15));
    _checkResponse(response);
  }

  Future<void> deleteTransaction(int id) async {
    final response = await _client
        .delete(Uri.parse('$apiBaseUrl/api/v1/transactions/$id'))
        .timeout(const Duration(seconds: 15));
    _checkResponse(response);
  }

  Future<StatementUploadResponse> uploadStatements({
    required List<({List<int> bytes, String name})> files,
    bool save = true,
  }) async {
    final uri = Uri.parse('$apiBaseUrl/api/v1/statements/upload?save=$save');
    final request = http.MultipartRequest('POST', uri);
    for (final file in files) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'files',
          file.bytes,
          filename: file.name,
        ),
      );
    }

    final timeoutSeconds = 60 + (files.length * 60);
    final streamedResponse =
        await request.send().timeout(Duration(seconds: timeoutSeconds));
    final response = await http.Response.fromStream(streamedResponse);
    _checkResponse(response);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return StatementUploadResponse.fromJson(data);
  }

  Future<StatementUploadResponse> uploadStatement({
    required List<int> fileBytes,
    required String filename,
    bool save = true,
  }) =>
      uploadStatements(
        files: [(bytes: fileBytes, name: filename)],
        save: save,
      );

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    var detail = response.body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['detail'] is String) {
        detail = decoded['detail'] as String;
      }
    } on FormatException {
      // Keep the response body as the error detail when it is not JSON.
    }
    throw Exception('API error (${response.statusCode}): $detail');
  }
}

String _formatDateTimeForApi(DateTime value) {
  final local = value.toLocal();
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}:${twoDigits(local.second)}';
}
