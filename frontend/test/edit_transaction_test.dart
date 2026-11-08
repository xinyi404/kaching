import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personal_finance_tracker/all_transactions_page.dart';
import 'package:personal_finance_tracker/api_service.dart';
import 'package:personal_finance_tracker/main.dart';

void main() {
  final testTx = TransactionRecord(
    id: 42,
    amount: 88.50,
    type: 'expense',
    currency: 'MYR',
    category: 'Food',
    merchant: 'GrabFood',
    description: 'Dinner with colleagues',
    occurredAt: DateTime(2026, 11, 5, 19, 30),
  );

  group('AddTransactionSheet (Edit Mode)', () {
    testWidgets('pre-populates existing transaction details correctly', (
      WidgetTester tester,
    ) async {
      TransactionDraft? savedDraft;

      await tester.pumpWidget(
        MaterialApp(
          theme: buildFinanceTheme(darkMode: false),
          home: Scaffold(
            body: AddTransactionSheet(
              initialTransaction: testTx,
              onSave: (draft) async {
                savedDraft = draft;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header and button text
      expect(find.text('Edit transaction'), findsOneWidget);
      expect(find.text('Update transaction'), findsOneWidget);

      // Pre-filled values
      expect(find.text('88.50'), findsOneWidget);
      expect(find.text('GrabFood'), findsOneWidget);
      expect(find.text('Dinner with colleagues'), findsOneWidget);
      expect(find.text('Food'), findsWidgets);

      // Modify amount, merchant, and notes
      await tester.enterText(find.widgetWithText(TextFormField, '88.50'), '99.00');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'GrabFood'),
        'ShopeeFood',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Dinner with colleagues'),
        'Lunch with team',
      );

      // Tap update
      await tester.tap(find.text('Update transaction'));
      await tester.pumpAndSettle();

      expect(savedDraft, isNotNull);
      expect(savedDraft!.amount, 99.00);
      expect(savedDraft!.merchant, 'ShopeeFood');
      expect(savedDraft!.description, 'Lunch with team');
      expect(savedDraft!.type, 'expense');
      expect(savedDraft!.category, 'Food');
    });

    testWidgets('allows changing transaction type and category', (
      WidgetTester tester,
    ) async {
      TransactionDraft? savedDraft;

      await tester.pumpWidget(
        MaterialApp(
          theme: buildFinanceTheme(darkMode: false),
          home: Scaffold(
            body: AddTransactionSheet(
              initialTransaction: testTx,
              onSave: (draft) async {
                savedDraft = draft;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Income
      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();

      // Income categories should now be available (default Salary)
      expect(find.text('Salary'), findsWidgets);

      // Tap update
      await tester.tap(find.text('Update transaction'));
      await tester.pumpAndSettle();

      expect(savedDraft, isNotNull);
      expect(savedDraft!.type, 'income');
      expect(savedDraft!.category, 'Salary');
    });

    testWidgets('shows delete button and confirms deletion', (
      WidgetTester tester,
    ) async {
      var deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: buildFinanceTheme(darkMode: false),
          home: Scaffold(
            body: AddTransactionSheet(
              initialTransaction: testTx,
              onSave: (draft) async {},
              onDelete: () async {
                deleted = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Delete icon button should be present
      final deleteBtn = find.byTooltip('Delete transaction');
      expect(deleteBtn, findsOneWidget);

      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog should be displayed
      expect(find.text('Delete transaction?'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to delete this recorded transaction? This action cannot be undone.',
        ),
        findsOneWidget,
      );

      // Confirm delete
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });
  });

  group('Edit Transaction Flow in AllTransactionsPage', () {
    testWidgets('tapping a transaction tile opens edit sheet and updates transaction', (
      WidgetTester tester,
    ) async {
      var putCalled = false;
      Map<String, dynamic>? putBody;

      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/v1/transactions') {
          return http.Response(
            jsonEncode([
              {
                'id': 42,
                'amount': '88.50',
                'transaction_type': 'expense',
                'currency': 'MYR',
                'category': 'Food',
                'merchant': 'GrabFood',
                'description': 'Dinner with colleagues',
                'occurred_at': DateTime.now().toIso8601String(),
              }
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'PUT' &&
            request.url.path == '/api/v1/transactions/42') {
          putCalled = true;
          putBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'id': 42,
              'amount': putBody!['amount'],
              'transaction_type': putBody!['transaction_type'],
              'currency': putBody!['currency'],
              'category': putBody!['category'],
              'merchant': putBody!['merchant'],
              'description': putBody!['description'],
              'occurred_at': putBody!['occurred_at'],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final api = FinanceApi(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildFinanceTheme(darkMode: false),
          home: AllTransactionsPage(api: api),
        ),
      );
      await tester.pumpAndSettle();

      // Verify transaction tile is present
      expect(find.text('GrabFood'), findsOneWidget);

      // Tap on transaction tile
      await tester.tap(find.text('GrabFood'));
      await tester.pumpAndSettle();

      // Edit sheet should now be open
      expect(find.text('Edit transaction'), findsOneWidget);
      expect(find.text('Update transaction'), findsOneWidget);

      // Change category or merchant
      await tester.enterText(
        find.widgetWithText(TextFormField, 'GrabFood'),
        'GrabFood Special',
      );

      // Save changes
      await tester.tap(find.text('Update transaction'));
      await tester.pumpAndSettle();

      expect(putCalled, isTrue);
      expect(putBody!['merchant'], 'GrabFood Special');
    });
  });
}
