import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/api_service.dart';
import 'package:personal_finance_tracker/main.dart';

void main() {
  testWidgets('renders Statement Result Sheet with extracted transactions and metrics', (
    tester,
  ) async {
    final response = StatementUploadResponse(
      filename: 'maybank_oct2026.pdf',
      institutionName: 'Maybank',
      statementPeriod: '01 Oct 2026 - 31 Oct 2026',
      currency: 'MYR',
      totalExtracted: 2,
      totalSaved: 1,
      duplicatesSkipped: 1,
      totalIncome: 4500.00,
      totalExpense: 120.50,
      transactions: [
        StatementTransactionItem(
          id: 1,
          amount: 4500.00,
          type: 'income',
          currency: 'MYR',
          merchant: 'Tech Corp Sdn Bhd',
          category: 'Salary',
          occurredAt: DateTime(2026, 10, 1),
          isDuplicate: false,
        ),
        StatementTransactionItem(
          id: null,
          amount: 120.50,
          type: 'expense',
          currency: 'MYR',
          merchant: 'Tenaga Nasional',
          category: 'Bills',
          occurredAt: DateTime(2026, 10, 15),
          isDuplicate: true,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFinanceTheme(darkMode: false),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => StatementResultSheet(response: response),
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      ),
    );

    // Tap to open sheet
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Maybank'), findsOneWidget);
    expect(find.text('01 Oct 2026 - 31 Oct 2026'), findsOneWidget);
    expect(find.text('New Saved'), findsOneWidget);
    expect(find.text('Duplicates'), findsOneWidget);
    expect(find.text('Tech Corp Sdn Bhd'), findsOneWidget);
    expect(find.text('Tenaga Nasional'), findsOneWidget);
    expect(find.text('Duplicate'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    // Tap Done to close
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Maybank'), findsNothing);
  });

  testWidgets(
      'renders Statement Result Sheet with multiple statements summary', (
    tester,
  ) async {
    final response = StatementUploadResponse(
      filename: '2 statements (maybank.pdf, tng.csv)',
      totalFiles: 2,
      institutionName: 'Maybank, Touch n Go eWallet',
      currency: 'MYR',
      totalExtracted: 5,
      totalSaved: 4,
      duplicatesSkipped: 1,
      totalIncome: 5000.00,
      totalExpense: 320.00,
      fileSummaries: const [
        StatementFileSummary(
          filename: 'maybank.pdf',
          institutionName: 'Maybank',
          totalExtracted: 3,
          totalSaved: 3,
          duplicatesSkipped: 0,
          totalIncome: 5000.00,
          totalExpense: 200.00,
        ),
        StatementFileSummary(
          filename: 'tng.csv',
          institutionName: 'Touch n Go eWallet',
          totalExtracted: 2,
          totalSaved: 1,
          duplicatesSkipped: 1,
          totalIncome: 0.00,
          totalExpense: 120.00,
        ),
      ],
      transactions: [
        StatementTransactionItem(
          id: 1,
          amount: 5000.00,
          type: 'income',
          currency: 'MYR',
          merchant: 'Tech Corp',
          category: 'Salary',
          occurredAt: DateTime(2026, 10, 1),
          isDuplicate: false,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFinanceTheme(darkMode: false),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) =>
                        StatementResultSheet(response: response),
                  );
                },
                child: const Text('Open Multi Sheet'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Multi Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Maybank, Touch n Go eWallet'), findsOneWidget);
    expect(find.textContaining('2 statements'), findsWidgets);
    expect(find.text('Maybank: 3 saved'), findsOneWidget);
    expect(find.text('Touch n Go eWallet: 1 saved'), findsOneWidget);
  });
}
