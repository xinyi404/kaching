import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/all_transactions_page.dart';
import 'package:personal_finance_tracker/api_service.dart';
import 'package:personal_finance_tracker/main.dart';
import 'package:personal_finance_tracker/stats_bar_chart.dart';

void main() {
  final now = DateTime.now();

  final tx1 = TransactionRecord(
    id: 1,
    amount: 150.0,
    type: 'expense',
    currency: 'MYR',
    category: 'Groceries',
    merchant: 'Jaya Grocer',
    occurredAt: DateTime(now.year, now.month, 5, 10, 0),
  );

  final tx2 = TransactionRecord(
    id: 2,
    amount: 50.0,
    type: 'expense',
    currency: 'MYR',
    category: 'Food',
    merchant: 'Zus Coffee',
    occurredAt: DateTime(now.year, now.month, 10, 14, 0),
  );

  final tx3 = TransactionRecord(
    id: 3,
    amount: 4000.0,
    type: 'income',
    currency: 'MYR',
    category: 'Salary',
    merchant: 'Tech Corp',
    occurredAt: DateTime(now.year, now.month, 1, 9, 0),
  );

  final transactions = [tx1, tx2, tx3];

  testWidgets(
    'StatsBarChartCard defaults to monthly granularity and current month',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFinanceTheme(darkMode: false),
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatsBarChartCard(
                transactions: transactions,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title & Date range badge
      expect(find.text('Cash Flow Stats'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);

      // Granularities
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Yearly'), findsOneWidget);

      // Summary totals (Income: 4000, Expense: 200)
      expect(find.textContaining('Income:'), findsOneWidget);
      expect(find.textContaining('Expense:'), findsOneWidget);
      expect(find.textContaining('Net: +MYR 3800'), findsOneWidget);
    },
  );

  testWidgets(
    'StatsBarChartCard switches between Daily, Monthly, and Yearly granularities',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFinanceTheme(darkMode: false),
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatsBarChartCard(
                transactions: transactions,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Daily
      await tester.tap(find.text('Daily'));
      await tester.pumpAndSettle();

      // Daily days (e.g. 1st, 5th, 10th)
      expect(find.text('1'), findsWidgets);
      expect(find.text('5'), findsWidgets);
      expect(find.text('10'), findsWidgets);

      // Switch to Yearly
      await tester.tap(find.text('Yearly'));
      await tester.pumpAndSettle();

      // Current year label
      expect(find.text('${now.year}'), findsWidgets);

      // Switch back to Monthly
      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'StatsBarChartCard tapping a bar shows detail banner and dismisses it',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFinanceTheme(darkMode: false),
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatsBarChartCard(
                transactions: transactions,
                initialGranularity: StatsGranularity.daily,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on day 10 bar column
      await tester.tap(find.text('10').first);
      await tester.pumpAndSettle();

      // Detail banner with +MYR 0.00 and −MYR 50.00
      expect(find.text('−MYR 50.00'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Close banner
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close_rounded), findsNothing);
    },
  );

  testWidgets(
    'StatsBarChartCard displays empty state when no transactions exist',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFinanceTheme(darkMode: false),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: StatsBarChartCard(
                transactions: [],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No transactions in this period'), findsOneWidget);
    },
  );

  testWidgets(
    'AllTransactionsPage toggles StatsBarChartCard via AppBar action',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFinanceTheme(darkMode: false),
          home: AllTransactionsPage(
            initialTransactions: transactions,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially, chart is not visible
      expect(find.text('Cash Flow Stats'), findsNothing);

      // Tap AppBar button to show stats chart
      await tester.tap(find.byTooltip('Show stats chart'));
      await tester.pumpAndSettle();

      // Chart is now visible!
      expect(find.text('Cash Flow Stats'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Yearly'), findsOneWidget);

      // Tap again to hide
      await tester.tap(find.byTooltip('Hide stats chart'));
      await tester.pumpAndSettle();

      expect(find.text('Cash Flow Stats'), findsNothing);
    },
  );
}
