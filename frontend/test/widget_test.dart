import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personal_finance_tracker/api_service.dart';
import 'package:personal_finance_tracker/main.dart';

void main() {
  testWidgets('dashboard renders when there are no transactions', (
    tester,
  ) async {
    final api = FinanceApi(
      client: MockClient((_) async => http.Response('[]', 200)),
    );
    addTearDown(api.close);
    var darkMode = false;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => MaterialApp(
          theme: buildFinanceTheme(darkMode: false),
          darkTheme: buildFinanceTheme(darkMode: true),
          themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
          home: FinanceHomePage(
            permissionStatus:
                'Notification capture is available on Android only',
            isDarkMode: darkMode,
            onToggleTheme: () => setState(() => darkMode = !darkMode),
            api: api,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TOTAL BALANCE'), findsOneWidget);
    expect(find.text('Cash flow'), findsOneWidget);
    expect(find.text('Spending by category'), findsOneWidget);
    await tester.drag(find.byType(Scrollable), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('No transactions yet. Add your first record.'),
        findsOneWidget);
    expect(find.text('Add transaction'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1000));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Turn on dark mode'));
    await tester.pumpAndSettle();
    expect(darkMode, isTrue);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    expect(find.byTooltip('Turn off dark mode'), findsOneWidget);
  });
}
