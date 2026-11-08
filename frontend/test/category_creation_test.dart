import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/main.dart';

void main() {
  testWidgets('plus button next to category is removed and category can be added via dropdown', (
    tester,
  ) async {
    TransactionDraft? savedDraft;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFinanceTheme(darkMode: false),
        home: Scaffold(
          body: AddTransactionSheet(
            onSave: (draft) async {
              savedDraft = draft;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial categories exist
    expect(find.text('Add transaction'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);

    // Verify plus button next to category is not present
    expect(find.byTooltip('Create new category'), findsNothing);

    // Tap the dropdown to open it
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    // Tap '+ Add new category...'
    await tester.tap(find.text('+ Add new category...'));
    await tester.pumpAndSettle();

    // Verify dialog appears
    expect(find.text('New Category'), findsOneWidget);
    expect(find.text('Category name'), findsOneWidget);

    // Enter new category name: 'Pet Care'
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Category name'),
      'Pet Care',
    );
    await tester.pumpAndSettle();

    // Tap 'Add category'
    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();

    // Verify 'Pet Care' is now selected in the dropdown
    expect(find.text('Pet Care'), findsOneWidget);

    // Enter amount
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount (MYR)'),
      '45.00',
    );
    await tester.pumpAndSettle();

    // Submit transaction
    await tester.tap(find.text('Save transaction'));
    await tester.pumpAndSettle();

    // Verify saved draft contains the new category
    expect(savedDraft, isNotNull);
    expect(savedDraft!.amount, 45.00);
    expect(savedDraft!.category, 'Pet Care');
    expect(savedDraft!.type, 'expense');
  });

  testWidgets('user can create a new category via dropdown + Add new category item', (
    tester,
  ) async {
    TransactionDraft? savedDraft;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFinanceTheme(darkMode: false),
        home: Scaffold(
          body: AddTransactionSheet(
            onSave: (draft) async {
              savedDraft = draft;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the dropdown to open it
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    // Tap '+ Add new category...'
    await tester.tap(find.text('+ Add new category...'));
    await tester.pumpAndSettle();

    // Dialog appears
    expect(find.text('New Category'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Category name'),
      'Fitness & Gym',
    );
    await tester.pumpAndSettle();

    // Add category
    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();

    // Verify selected
    expect(find.text('Fitness & Gym'), findsOneWidget);

    // Enter amount and save
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount (MYR)'),
      '120.00',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save transaction'));
    await tester.pumpAndSettle();

    expect(savedDraft, isNotNull);
    expect(savedDraft!.amount, 120.00);
    expect(savedDraft!.category, 'Fitness & Gym');
  });
}
