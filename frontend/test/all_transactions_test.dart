import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personal_finance_tracker/all_transactions_page.dart';
import 'package:personal_finance_tracker/api_service.dart';
import 'package:personal_finance_tracker/date_range_picker_dialog.dart';
import 'package:personal_finance_tracker/main.dart';

void main() {
  final now = DateTime.now();
  final currentMonthTx = TransactionRecord(
    id: 1,
    amount: 50.0,
    type: 'expense',
    currency: 'MYR',
    category: 'Food',
    merchant: 'Zus Coffee',
    occurredAt: DateTime(now.year, now.month, 10, 14, 0),
  );

  final previousMonthDate = DateTime(now.year, now.month - 1, 15, 10, 0);
  final previousMonthTx = TransactionRecord(
    id: 2,
    amount: 150.0,
    type: 'expense',
    currency: 'MYR',
    category: 'Groceries',
    merchant: 'Jaya Grocer',
    occurredAt: previousMonthDate,
  );

  final salaryTx = TransactionRecord(
    id: 3,
    amount: 5000.0,
    type: 'income',
    currency: 'MYR',
    category: 'Salary',
    merchant: 'Tech Corp',
    occurredAt: DateTime(now.year, now.month, 1, 9, 0),
  );

  testWidgets('AllTransactionsPage defaults to current month and filters correctly', (
    WidgetTester tester,
  ) async {
    final transactions = [currentMonthTx, previousMonthTx, salaryTx];

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFinanceTheme(darkMode: false),
        home: AllTransactionsPage(
          initialTransactions: transactions,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify title and default filter
    expect(find.text('All Transactions'), findsOneWidget);
    expect(find.text('This Month'), findsWidgets);

    // Current month transactions should be visible
    expect(find.text('Zus Coffee'), findsOneWidget);
    expect(find.text('Tech Corp'), findsOneWidget);

    // Previous month transaction should NOT be visible by default
    expect(find.text('Jaya Grocer'), findsNothing);

    // Verify summary values for current month (Income: 5000, Expense: 50)
    expect(find.text('+MYR 5000.00'), findsWidgets);
    expect(find.text('−MYR 50.00'), findsWidgets);
    expect(find.text('+MYR 4950.00'), findsOneWidget);
    expect(find.text('Transactions (2)'), findsOneWidget);

    // Test Type Filter: tap 'Expenses' chip
    await tester.tap(find.widgetWithText(ChoiceChip, 'Expenses'));
    await tester.pumpAndSettle();
    expect(find.text('Zus Coffee'), findsOneWidget);
    expect(find.text('Tech Corp'), findsNothing);
    expect(find.text('Transactions (1)'), findsOneWidget);

    // Tap 'Income' chip
    await tester.tap(find.widgetWithText(ChoiceChip, 'Income'));
    await tester.pumpAndSettle();
    expect(find.text('Tech Corp'), findsOneWidget);
    expect(find.text('Zus Coffee'), findsNothing);

    // Tap 'All' chip
    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();
    expect(find.text('Tech Corp'), findsOneWidget);
    expect(find.text('Zus Coffee'), findsOneWidget);

    // Test search filter
    await tester.enterText(find.byType(TextField), 'Zus');
    await tester.pumpAndSettle();
    expect(find.text('Zus Coffee'), findsOneWidget);
    expect(find.text('Tech Corp'), findsNothing);
    expect(find.text('Transactions (1)'), findsOneWidget);

    // Clear search
    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Tech Corp'), findsOneWidget);
    expect(find.text('Zus Coffee'), findsOneWidget);
  });

  testWidgets('Date range picker opens and can select All time preset', (
    WidgetTester tester,
  ) async {
    final transactions = [currentMonthTx, previousMonthTx, salaryTx];

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFinanceTheme(darkMode: false),
        home: AllTransactionsPage(
          initialTransactions: transactions,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open Date Range Picker by tapping the filter bar
    await tester.tap(find.byIcon(Icons.calendar_month_rounded));
    await tester.pumpAndSettle();

    // Verify dialog with presets is opened
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.text('This Month'), findsWidgets);
    expect(find.text('Last Month'), findsOneWidget);
    expect(find.text('Last 3 months'), findsOneWidget);
    expect(find.text('All Time'), findsOneWidget);

    // Verify removed presets are no longer present
    expect(find.text('Last 30 days'), findsNothing);
    expect(find.text('Last 6 months'), findsNothing);
    expect(find.text('Last year'), findsNothing);

    // Verify Apply and Cancel buttons exist
    expect(find.text('Apply'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Tap 'All Time' preset
    await tester.tap(find.text('All Time'));
    await tester.pumpAndSettle();

    // Tap 'Apply'
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    // Now all 3 transactions should be in the list!
    expect(find.text('Transactions (3)'), findsOneWidget);
    expect(find.text('Jaya Grocer'), findsOneWidget);
    expect(find.text('Zus Coffee'), findsOneWidget);

    // Scroll down to see Tech Corp if it is below viewport
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Tech Corp'), findsOneWidget);
  });

  testWidgets('Date range picker can select Last Month preset', (
    WidgetTester tester,
  ) async {
    final transactions = [currentMonthTx, previousMonthTx, salaryTx];

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFinanceTheme(darkMode: false),
        home: AllTransactionsPage(
          initialTransactions: transactions,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open Date Range Picker
    await tester.tap(find.byIcon(Icons.calendar_month_rounded));
    await tester.pumpAndSettle();

    // Tap 'Last Month' preset
    await tester.tap(find.text('Last Month'));
    await tester.pumpAndSettle();

    // Tap 'Apply'
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    // Only previous month transaction (Jaya Grocer) should be visible!
    expect(find.text('Transactions (1)'), findsOneWidget);
    expect(find.text('Jaya Grocer'), findsOneWidget);
    expect(find.text('Zus Coffee'), findsNothing);
    expect(find.text('Tech Corp'), findsNothing);
  });

  testWidgets('Navigation from FinanceHomePage to AllTransactionsPage works', (
    WidgetTester tester,
  ) async {
    final api = FinanceApi(
      client: MockClient((_) async => http.Response('[]', 200)),
    );
    addTearDown(api.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFinanceTheme(darkMode: false),
        home: FinanceHomePage(
          permissionStatus: 'Not available',
          isDarkMode: false,
          onToggleTheme: () {},
          api: api,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Find and tap "Show all" in Recent transactions section
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('Show all'), findsOneWidget);
    await tester.tap(find.text('Show all'));
    await tester.pumpAndSettle();

    // Verify we arrived on AllTransactionsPage
    expect(find.text('All Transactions'), findsOneWidget);
    expect(find.text('This Month'), findsWidgets);

    // Tap back button
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // Verify we are back on home page
    expect(find.text('Recent transactions'), findsOneWidget);
  });

  testWidgets('DateRangePickerDialog cancel button dismisses without changes', (
    WidgetTester tester,
  ) async {
    DateRangeResult? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFinanceTheme(darkMode: false),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showCustomDateRangePicker(
                  context: context,
                  initialStart: DateTime(2024, 5, 1),
                  initialEnd: DateTime(2024, 5, 31),
                  initialPreset: 'This Month',
                );
              },
              child: const Text('Open Picker'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    expect(find.text('Apply'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(find.text('Apply'), findsNothing);
  });

  testWidgets('AllTransactionsPage shows empty state when date range has no transactions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFinanceTheme(darkMode: false),
        home: const AllTransactionsPage(
          initialTransactions: [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No transactions in this period'), findsOneWidget);
    expect(find.text('Current Month'), findsOneWidget);
    expect(find.text('View All Time'), findsOneWidget);
  });

  testWidgets('AllTransactionsPage and DateRangePickerDialog do not overflow on narrow phone screen', (
    WidgetTester tester,
  ) async {
    // Simulate narrow phone screen (360x640)
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFinanceTheme(darkMode: false),
        home: AllTransactionsPage(
          initialTransactions: [
            TransactionRecord(
              id: 1,
              amount: 11229.12,
              type: 'expense',
              currency: 'MYR',
              category: 'Other',
              occurredAt: DateTime.now(),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify filter bar rendered without overflow
    expect(find.text('This Month'), findsWidgets);
    expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);

    // Open Date Range Picker on narrow screen
    await tester.tap(find.byIcon(Icons.calendar_month_rounded));
    await tester.pumpAndSettle();

    // Verify dialog header, presets, and action buttons are present and visible
    expect(find.text('Select Date Range'), findsOneWidget);
    expect(find.text('This Month'), findsWidgets);
    expect(find.text('Apply'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Tap Apply directly without any horizontal scroll
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('Select Date Range'), findsNothing);
  });
}
