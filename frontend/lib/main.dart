// frontend/lib/main.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'all_transactions_page.dart';
import 'analytics_page.dart';
import 'api_service.dart';
import 'background_sync.dart';
import 'notification_capture.dart';
import 'pending_notifications.dart';
import 'stats_bar_chart.dart';
import 'sync_service.dart' hide enqueuePendingSync;

const _ink = Color(0xFF0B1A3A);
const _red = Color(0xFFD92D3F);
const _blue = Color(0xFF14307A);
const _lightBlue = Color(0xFFEEF2F8);
const _sand = Color(0xFFE8ECF4);
const _paper = Color(0xFFF5F7FB);
const _muted = Color(0xFF5B6785);
const _primary = Color(0xFFFF6B1A);
const _secondary = Color(0xFF14307A);
const _accent = Color(0xFFFFEDE1);
const _accentForeground = Color(0xFFB83E00);
const _green = Color(0xFF059669);
const _chart1 = Color(0xFF1F4FD8);
const _chart2 = Color(0xFFFF6B1A);
const _chart3 = Color(0xFF0F9D8A);
const _chart4 = Color(0xFFF5B301);
const _chart5 = Color(0xFF64748B);

@immutable
class FinanceColors extends ThemeExtension<FinanceColors> {
  const FinanceColors({
    required this.ink,
    required this.muted,
    required this.background,
    required this.surface,
    required this.border,
    required this.chartTrack,
    required this.errorSurface,
    required this.red,
    required this.blue,
    required this.lightBlue,
    required this.sand,
    required this.balanceSurface,
    this.primary = _primary,
    this.secondary = _secondary,
    this.accent = _accent,
    this.accentForeground = _accentForeground,
    this.green = _green,
    this.chart1 = _chart1,
    this.chart2 = _chart2,
    this.chart3 = _chart3,
    this.chart4 = _chart4,
    this.chart5 = _chart5,
  });

  final Color ink;
  final Color muted;
  final Color background;
  final Color surface;
  final Color border;
  final Color chartTrack;
  final Color errorSurface;
  final Color red;
  final Color blue;
  final Color lightBlue;
  final Color sand;
  final Color balanceSurface;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color accentForeground;
  final Color green;
  final Color chart1;
  final Color chart2;
  final Color chart3;
  final Color chart4;
  final Color chart5;

  static const light = FinanceColors(
    ink: _ink,
    muted: _muted,
    background: _paper,
    surface: Colors.white,
    border: Color(0xFFE1E6F0),
    chartTrack: Color(0xFFE8ECF4),
    errorSurface: Color(0xFFFFECEE),
    red: _red,
    blue: _blue,
    lightBlue: _lightBlue,
    sand: _sand,
    balanceSurface: _secondary,
    primary: _primary,
    secondary: _secondary,
    accent: _accent,
    accentForeground: _accentForeground,
    green: _green,
    chart1: _chart1,
    chart2: _chart2,
    chart3: _chart3,
    chart4: _chart4,
    chart5: _chart5,
  );

  static const dark = FinanceColors(
    ink: Color(0xFFF5F7FB),
    muted: Color(0xFF8E9BB5),
    background: Color(0xFF081226),
    surface: Color(0xFF0F1E3D),
    border: Color(0xFF1D2E54),
    chartTrack: Color(0xFF1D2E54),
    errorSurface: Color(0xFF331418),
    red: Color(0xFFFF5263),
    blue: Color(0xFF2B52B0),
    lightBlue: Color(0xFF1D2E54),
    sand: Color(0xFF1D2E54),
    balanceSurface: Color(0xFF0A1633),
    primary: Color(0xFFFF7A33),
    secondary: Color(0xFF14307A),
    accent: Color(0xFF2C1E18),
    accentForeground: Color(0xFFFF9458),
    green: Color(0xFF10B981),
    chart1: Color(0xFF3B82F6),
    chart2: Color(0xFFFF7A33),
    chart3: Color(0xFF14B8A6),
    chart4: Color(0xFFFBBF24),
    chart5: Color(0xFF94A3B8),
  );

  @override
  FinanceColors copyWith({
    Color? ink,
    Color? muted,
    Color? background,
    Color? surface,
    Color? border,
    Color? chartTrack,
    Color? errorSurface,
    Color? red,
    Color? blue,
    Color? lightBlue,
    Color? sand,
    Color? balanceSurface,
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? accentForeground,
    Color? green,
    Color? chart1,
    Color? chart2,
    Color? chart3,
    Color? chart4,
    Color? chart5,
  }) {
    return FinanceColors(
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      chartTrack: chartTrack ?? this.chartTrack,
      errorSurface: errorSurface ?? this.errorSurface,
      red: red ?? this.red,
      blue: blue ?? this.blue,
      lightBlue: lightBlue ?? this.lightBlue,
      sand: sand ?? this.sand,
      balanceSurface: balanceSurface ?? this.balanceSurface,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      accentForeground: accentForeground ?? this.accentForeground,
      green: green ?? this.green,
      chart1: chart1 ?? this.chart1,
      chart2: chart2 ?? this.chart2,
      chart3: chart3 ?? this.chart3,
      chart4: chart4 ?? this.chart4,
      chart5: chart5 ?? this.chart5,
    );
  }

  @override
  FinanceColors lerp(
    covariant ThemeExtension<FinanceColors>? other,
    double t,
  ) {
    if (other is! FinanceColors) return this;
    return FinanceColors(
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      border: Color.lerp(border, other.border, t)!,
      chartTrack: Color.lerp(chartTrack, other.chartTrack, t)!,
      errorSurface: Color.lerp(errorSurface, other.errorSurface, t)!,
      red: Color.lerp(red, other.red, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      lightBlue: Color.lerp(lightBlue, other.lightBlue, t)!,
      sand: Color.lerp(sand, other.sand, t)!,
      balanceSurface: Color.lerp(balanceSurface, other.balanceSurface, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentForeground:
          Color.lerp(accentForeground, other.accentForeground, t)!,
      green: Color.lerp(green, other.green, t)!,
      chart1: Color.lerp(chart1, other.chart1, t)!,
      chart2: Color.lerp(chart2, other.chart2, t)!,
      chart3: Color.lerp(chart3, other.chart3, t)!,
      chart4: Color.lerp(chart4, other.chart4, t)!,
      chart5: Color.lerp(chart5, other.chart5, t)!,
    );
  }
}

typedef _FinanceColors = FinanceColors;

ThemeData _buildTheme(_FinanceColors colors, Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: colors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _blue,
      brightness: brightness,
      surface: colors.surface,
      onSurface: colors.ink,
      error: colors.red,
    ),
    extensions: [colors],
    fontFamily: 'Roboto',
  );
}

ThemeData buildFinanceTheme({required bool darkMode}) => _buildTheme(
      darkMode ? _FinanceColors.dark : _FinanceColors.light,
      darkMode ? Brightness.dark : Brightness.light,
    );

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeBackgroundSync();
  runApp(const FinanceTrackerApp());
}

class FinanceTrackerApp extends StatefulWidget {
  const FinanceTrackerApp({super.key});

  @override
  State<FinanceTrackerApp> createState() => _FinanceTrackerAppState();
}

class _FinanceTrackerAppState extends State<FinanceTrackerApp> {
  String _permissionStatus = 'Checking notification access…';
  bool _isDarkMode = false;
  late final NotificationCapture _notificationCapture;
  final GlobalKey<_FinanceHomePageState> _homeKey =
      GlobalKey<_FinanceHomePageState>();

  @override
  void initState() {
    super.initState();
    _notificationCapture = NotificationCapture();
    _initializeNotificationListener();
  }

  Future<void> _initializeNotificationListener() async {
    final status = await _notificationCapture.start(
      (packageName, title, text) async {
        await storePendingNotification(
          packageName: packageName,
          title: title,
          text: text,
          createdAt: DateTime.now(),
        );
        if (_homeKey.currentState != null && _homeKey.currentState!.mounted) {
          _homeKey.currentState!._loadTransactions();
        } else {
          await enqueuePendingSync();
        }
      },
    );
    if (!mounted) return;
    setState(() => _permissionStatus = status);
  }

  @override
  void dispose() {
    unawaited(_notificationCapture.dispose());
    super.dispose();
  }

  void _toggleTheme() {
    setState(() => _isDarkMode = !_isDarkMode);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kaching',
        theme: buildFinanceTheme(darkMode: false),
        darkTheme: buildFinanceTheme(darkMode: true),
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: FinanceHomePage(
          key: _homeKey,
          permissionStatus: _permissionStatus,
          isDarkMode: _isDarkMode,
          onToggleTheme: _toggleTheme,
          notificationCapture: _notificationCapture,
        ),
      );
}

class FinanceHomePage extends StatefulWidget {
  const FinanceHomePage({
    required this.permissionStatus,
    required this.isDarkMode,
    required this.onToggleTheme,
    this.notificationCapture,
    this.api,
    super.key,
  });

  final String permissionStatus;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final NotificationCapture? notificationCapture;
  final FinanceApi? api;

  @override
  State<FinanceHomePage> createState() => _FinanceHomePageState();
}

class _FinanceHomePageState extends State<FinanceHomePage> {
  late final FinanceApi _api;
  List<TransactionRecord> _transactions = const [];
  bool _loading = true;
  String? _loadError;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? FinanceApi();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    // 1. Fetch current transactions from database immediately so UI displays fast
    try {
      final transactions = await _api.getTransactions();
      if (mounted) {
        setState(() {
          _transactions = transactions;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = error.toString();
        });
      }
    }

    // 2. Scan active status bar notifications & sync pending queue in background
    if (widget.notificationCapture != null) {
      try {
        await widget.notificationCapture!.checkActiveNotifications(
          (packageName, title, text) async {
            await storePendingNotification(
              packageName: packageName,
              title: title,
              text: text,
              createdAt: DateTime.now(),
            );
          },
        );

        final savedCount = await syncPendingNotifications();
        if (savedCount > 0 && mounted) {
          final updated = await _api.getTransactions();
          if (mounted) {
            setState(() => _transactions = updated);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF255C99),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                content: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Recorded $savedCount new transaction(s) to database!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('[Main] Notification sync error: $e');
      }
    }
  }

  Future<void> _showAddTransaction() async {
    final existingCategories = _transactions
        .map((t) => t.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddTransactionSheet(
        existingCategories: existingCategories,
        onSave: (draft) => _api.createTransaction(
          amount: draft.amount,
          type: draft.type,
          currency: draft.currency,
          category: draft.category,
          occurredAt: draft.occurredAt,
          merchant: draft.merchant,
          description: draft.description,
        ),
      ),
    );
    if (saved == true) await _loadTransactions();
  }

  Future<void> _editTransaction(TransactionRecord transaction) async {
    final existingCategories = _transactions
        .map((t) => t.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddTransactionSheet(
        initialTransaction: transaction,
        existingCategories: existingCategories,
        onSave: (draft) => _api.updateTransaction(
          id: transaction.id,
          amount: draft.amount,
          type: draft.type,
          currency: draft.currency,
          category: draft.category,
          occurredAt: draft.occurredAt,
          merchant: draft.merchant,
          description: draft.description,
        ),
        onDelete: () => _api.deleteTransaction(transaction.id),
      ),
    );
    if (saved == true) await _loadTransactions();
  }

  bool _importing = false;

  Future<void> _importStatement() async {
    try {
      final pickedFiles = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'xlsx', 'xls', 'csv', 'txt'],
      );

      if (pickedFiles.isEmpty) return;

      final filesPayload = <({List<int> bytes, String name})>[];
      for (final pf in pickedFiles) {
        final b = await pf.xFile.readAsBytes();
        if (b.isNotEmpty) {
          filesPayload.add((bytes: b, name: pf.name));
        }
      }

      if (filesPayload.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read any of the selected files.'),
          ),
        );
        return;
      }

      setState(() => _importing = true);

      final fileCount = filesPayload.length;
      final dialogSubtitle = fileCount == 1
          ? 'Analyzing ${filesPayload.first.name} with Gemini AI...'
          : 'Analyzing $fileCount statements with Gemini AI...';

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  const CircularProgressIndicator(color: _blue),
                  const SizedBox(height: 20),
                  Text(
                    fileCount == 1
                        ? 'AI Extracting Statement'
                        : 'AI Extracting $fileCount Statements',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dialogSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _muted, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      );

      final response = await _api.uploadStatements(
        files: filesPayload,
        save: true,
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      setState(() => _importing = false);

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => StatementResultSheet(response: response),
      );

      await _loadTransactions();
    } catch (e) {
      if (!mounted) return;
      if (_importing) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _importing = false);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text('Import failed: $e'),
        ),
      );
    }
  }

  void _openAllTransactions() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AllTransactionsPage(
          api: _api,
          initialTransactions: _transactions,
          onTransactionAdded: _loadTransactions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<_FinanceColors>()!;
    final now = DateTime.now();
    final thisMonth = _transactions
        .where((item) =>
            item.occurredAt.year == now.year &&
            item.occurredAt.month == now.month)
        .toList(growable: false);
    final income = _sum(thisMonth, 'income');
    final expenses = _sum(thisMonth, 'expense');
    final totalBalance =
        _sum(_transactions, 'income') - _sum(_transactions, 'expense');
    final expensesByCategory = <String, double>{};
    for (final transaction
        in thisMonth.where((item) => item.type == 'expense')) {
      expensesByCategory.update(
        transaction.category,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    Widget body;
    if (_selectedTabIndex == 1) {
      body = AllTransactionsPage(
        api: _api,
        initialTransactions: _transactions,
        onTransactionAdded: _loadTransactions,
      );
    } else if (_selectedTabIndex == 2) {
      body = AnalyticsPage(
        transactions: _transactions,
      );
    } else {
      body = RefreshIndicator(
        color: colors.primary,
        onRefresh: _loadTransactions,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
          children: [
            _buildHeader(colors),
            const SizedBox(height: 22),
            _BalanceCard(balance: totalBalance),
            StatementImportBanner(onImport: _importStatement),
            if (_loadError != null && _transactions.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ErrorCard(message: _loadError!, onRetry: _loadTransactions),
            ],
            const SizedBox(height: 18),
            _SectionHeading(
              title: 'Cash flow',
              subtitle: _monthLabel(now),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _CashFlowCard(
                    label: 'Income',
                    amount: income,
                    color: colors.green,
                    icon: Icons.south_west_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CashFlowCard(
                    label: 'Expenses',
                    amount: expenses,
                    color: colors.red,
                    icon: Icons.north_east_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _SectionHeading(
              title: 'Spending by category',
              subtitle: 'This month',
            ),
            const SizedBox(height: 12),
            _ExpenseBreakdown(values: expensesByCategory),
            if (_transactions.isNotEmpty) ...[
              const SizedBox(height: 22),
              _SectionHeading(
                title: 'Cash flow trends',
                subtitle: 'Income vs expenses',
              ),
              const SizedBox(height: 12),
              StatsBarChartCard(transactions: _transactions),
            ],
            const SizedBox(height: 16),
            _buildQuickActions(colors),
            const SizedBox(height: 22),
            _SectionHeading(
              title: 'Recent transactions',
              subtitle: 'Latest activity',
              actionLabel: 'Show all',
              onAction: _openAllTransactions,
            ),
            const SizedBox(height: 12),
            if (_loading && _transactions.isEmpty)
              const _MessageCard(
                icon: Icons.sync_rounded,
                message: 'Loading your transactions…',
              )
            else if (_loadError != null && _transactions.isEmpty)
              _ErrorCard(message: _loadError!, onRetry: _loadTransactions)
            else if (_transactions.isEmpty)
              const _MessageCard(
                icon: Icons.receipt_long_outlined,
                message: 'No transactions yet. Add your first record.',
              )
            else ...[
              ..._transactions.take(5).map(
                    (transaction) => _TransactionTile(
                      transaction: transaction,
                      onTap: () => _editTransaction(transaction),
                    ),
                  ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openAllTransactions,
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: Text(
                    'Show all transactions (${_transactions.length})',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.ink,
                    side: BorderSide(color: colors.border, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _PermissionCard(status: widget.permissionStatus),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: body,
      ),
      bottomNavigationBar: _buildBottomNav(colors),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'import_statement_fab',
            onPressed: _importing ? null : _importStatement,
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Import statement'),
          ),
          const SizedBox(width: 10),
          FloatingActionButton.extended(
            heroTag: 'add_tx_fab',
            onPressed: _showAddTransaction,
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add transaction'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(_FinanceColors colors) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: colors.primary,
            borderRadius: BorderRadius.circular(18),
            elevation: 2,
            shadowColor: colors.primary.withValues(alpha: 0.35),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _showAddTransaction,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Transaction',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Material(
            color: colors.accent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _importStatement,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.accentForeground.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.receipt_long_rounded,
                          color: colors.accentForeground, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Import',
                            style: TextStyle(
                              color: colors.accentForeground,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Statement AI',
                            style: TextStyle(
                              color: colors.accentForeground.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(_FinanceColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
        boxShadow: [
          BoxShadow(
            color: colors.ink.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: (index) {
          if (index == 3) {
            _showAddTransaction();
          } else {
            setState(() => _selectedTabIndex = index);
          }
        },
        backgroundColor: Colors.transparent,
        indicatorColor: colors.primary.withValues(alpha: 0.15),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: colors.muted),
            selectedIcon: Icon(Icons.home_rounded, color: colors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined, color: colors.muted),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: colors.primary),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, color: colors.muted),
            selectedIcon: Icon(Icons.bar_chart_rounded, color: colors.primary),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded, color: colors.muted),
            selectedIcon: Icon(Icons.add_circle_rounded, color: colors.primary),
            label: 'Add',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(_FinanceColors colors) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: colors.ink,
            borderRadius: BorderRadius.circular(15),
          ),
          alignment: Alignment.center,
          child: Text(
            'K',
            style: TextStyle(
              color: colors.sand,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kaching',
                style: TextStyle(
                  color: colors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Your money, in focus',
                style: TextStyle(color: colors.muted, fontSize: 13),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Import Statement (PDF, Excel, CSV)',
          onPressed: _importing ? null : _importStatement,
          icon: Icon(Icons.upload_file_rounded, color: colors.blue),
        ),
        IconButton(
          tooltip: 'Show all transactions',
          onPressed: _openAllTransactions,
          icon: Icon(Icons.receipt_long_rounded, color: colors.ink),
        ),
        IconButton(
          tooltip: 'Refresh transactions',
          onPressed: _loadTransactions,
          icon: Icon(Icons.refresh_rounded, color: colors.ink),
        ),
        IconButton(
          tooltip:
              widget.isDarkMode ? 'Turn off dark mode' : 'Turn on dark mode',
          onPressed: widget.onToggleTheme,
          icon: Icon(
            widget.isDarkMode
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            color: colors.ink,
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
  });

  final double balance;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<_FinanceColors>() ??
        _FinanceColors.light;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL BALANCE',
            style: TextStyle(
              color: colors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "${balance >= 0 ? '+' : '−'}${_money(balance.abs(), 'MYR')}",
            style: TextStyle(
              color: colors.ink,
              fontSize: 32,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<_FinanceColors>() ??
        _FinanceColors.light;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: colors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: colors.primary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CashFlowCard extends StatelessWidget {
  const _CashFlowCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<_FinanceColors>() ??
        _FinanceColors.light;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _money(amount, 'MYR'),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseBreakdown extends StatelessWidget {
  const _ExpenseBreakdown({required this.values});

  final Map<String, double> values;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<_FinanceColors>() ??
        _FinanceColors.light;
    final entries = values.entries.toList()
      ..sort((first, second) => second.value.compareTo(first.value));
    final colors = [
      palette.chart1,
      palette.chart2,
      palette.chart3,
      palette.chart4,
      palette.chart5,
      palette.secondary,
    ];
    final total = entries.fold<double>(0, (sum, entry) => sum + entry.value);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: entries.isEmpty
          ? SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'No expenses recorded this month',
                  style: TextStyle(color: palette.muted, fontSize: 13),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size.square(100),
                            painter: _DonutPainter(
                              values:
                                  entries.map((entry) => entry.value).toList(),
                              colors: colors,
                              trackColor: palette.chartTrack,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'TOTAL',
                                style: TextStyle(
                                  color: palette.muted,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 1),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    _compactMoney(total),
                                    style: TextStyle(
                                      color: palette.ink,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          for (var i = 0; i < math.min(entries.length, 3); i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: colors[i % colors.length],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      entries[i].key,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: palette.ink,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(entries[i].value / total * 100).round()}%',
                                    style: TextStyle(
                                      color: palette.muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Animated Progress Bars
                for (var i = 0; i < math.min(entries.length, 3); i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      tween: Tween(
                        begin: 0.0,
                        end: (entries[i].value / total).clamp(0.0, 1.0),
                      ),
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        backgroundColor: palette.chartTrack,
                        valueColor:
                            AlwaysStoppedAnimation(colors[i % colors.length]),
                        minHeight: 6,
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.values,
    required this.colors,
    required this.trackColor,
  });

  final List<double> values;
  final List<Color> colors;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, value) => sum + value);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 5;
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (total <= 0) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 22,
      );
      return;
    }

    var start = -1.5708;
    for (var index = 0; index < values.length; index++) {
      final sweep = values[index] / total * 6.2832;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = colors[index % colors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 22
          ..strokeCap = StrokeCap.butt,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.colors != colors ||
      oldDelegate.trackColor != trackColor;
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    required this.transaction,
    this.onTap,
    super.key,
  });

  final TransactionRecord transaction;
  final VoidCallback? onTap;

  static String getMonogram(String? merchant, String category) {
    final name = (merchant?.trim().isNotEmpty == true)
        ? merchant!.trim()
        : category.trim();
    final words =
        name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) {
      final first = words[0][0].toUpperCase();
      final second = words[1][0].toUpperCase();
      return '$first$second';
    } else if (name.length >= 2) {
      return name.substring(0, 2).toUpperCase();
    } else if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return 'TX';
  }

  static Color getMonogramColor(String key, FinanceColors palette) {
    final list = [
      palette.secondary,
      palette.chart1,
      palette.chart2,
      palette.chart3,
      palette.chart4,
    ];
    final hash = key.codeUnits.fold<int>(0, (sum, c) => sum + c);
    return list[hash % list.length];
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<_FinanceColors>() ??
        _FinanceColors.light;
    final isIncome = transaction.type == 'income';
    final amountColor = isIncome ? palette.green : palette.red;
    final title = transaction.merchant?.trim().isNotEmpty == true
        ? transaction.merchant!.trim()
        : transaction.category;
    final monogram = getMonogram(transaction.merchant, transaction.category);
    final badgeColor = getMonogramColor(title, palette);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              // Monogram Avatar Circle
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      monogram,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: palette.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.surface, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${transaction.category} · ${_dateLabel(transaction.occurredAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isIncome
                        ? Icons.arrow_outward_rounded
                        : Icons.south_west_rounded,
                    size: 14,
                    color: amountColor,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${isIncome ? '+' : '−'}${_money(transaction.amount, transaction.currency)}',
                    style: TextStyle(
                      color: amountColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: palette.muted.withValues(alpha: 0.5),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef _TransactionTile = TransactionTile;

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<_FinanceColors>()!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: palette.lightBlue),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: palette.muted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<_FinanceColors>()!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.errorSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Could not load transactions',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(message, style: TextStyle(color: palette.ink, fontSize: 12)),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<_FinanceColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: palette.blue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active_outlined,
            color: palette.blue,
            size: 17,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              status,
              style: TextStyle(color: palette.blue, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionDraft {
  const TransactionDraft({
    required this.amount,
    required this.type,
    required this.currency,
    required this.category,
    required this.occurredAt,
    this.merchant,
    this.description,
  });

  final double amount;
  final String type;
  final String currency;
  final String category;
  final DateTime occurredAt;
  final String? merchant;
  final String? description;
}

typedef _TransactionDraft = TransactionDraft;

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({
    super.key,
    required this.onSave,
    this.initialTransaction,
    this.onDelete,
    this.existingCategories = const [],
  });

  final Future<void> Function(TransactionDraft draft) onSave;
  final TransactionRecord? initialTransaction;
  final Future<void> Function()? onDelete;
  final List<String> existingCategories;

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

typedef _AddTransactionSheet = AddTransactionSheet;

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  static const _defaultExpenseCategories = [
    'Food',
    'Transport',
    'Bills',
    'Shopping',
    'Health',
    'Entertainment',
    'Groceries',
    'Other',
  ];
  static const _defaultIncomeCategories = [
    'Salary',
    'Freelance',
    'Investment',
    'Gift',
    'Other',
  ];

  late final List<String> _expenseCategories;
  late final List<String> _incomeCategories;

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _type = 'expense';
  late String _category;
  DateTime _occurredAt = DateTime.now();
  bool _saving = false;
  bool _deleting = false;
  String? _error;

  bool get _isEditing => widget.initialTransaction != null;

  List<String> get _categories =>
      _type == 'income' ? _incomeCategories : _expenseCategories;

  @override
  void initState() {
    super.initState();
    _expenseCategories = List.of(_defaultExpenseCategories);
    _incomeCategories = List.of(_defaultIncomeCategories);

    for (final cat in widget.existingCategories) {
      if (!_expenseCategories.contains(cat) &&
          !_incomeCategories.contains(cat)) {
        _expenseCategories.insert(_expenseCategories.length - 1, cat);
      }
    }

    if (widget.initialTransaction != null) {
      final tx = widget.initialTransaction!;
      _type = tx.type;
      _amountController.text = tx.amount.toStringAsFixed(2);
      if (tx.merchant != null && tx.merchant!.isNotEmpty) {
        _merchantController.text = tx.merchant!;
      }
      if (tx.description != null && tx.description!.isNotEmpty) {
        _descriptionController.text = tx.description!;
      }
      _occurredAt = tx.occurredAt;

      final targetList =
          _type == 'income' ? _incomeCategories : _expenseCategories;
      if (!targetList.contains(tx.category)) {
        final otherIdx = targetList.indexOf('Other');
        if (otherIdx != -1) {
          targetList.insert(otherIdx, tx.category);
        } else {
          targetList.add(tx.category);
        }
      }
      _category = tx.category;
    } else {
      _category = _categories.first;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _showAddCategoryDialog() async {
    final textController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    final newCategory = await showDialog<String>(
      context: context,
      builder: (dialogCtx) {
        final palette = Theme.of(dialogCtx).extension<_FinanceColors>()!;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              Icon(Icons.label_outline_rounded,
                  color: palette.blue, size: 22),
              const SizedBox(width: 8),
              const Text(
                'New Category',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
          content: Form(
            key: dialogFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add a category for your ${_type == 'income' ? 'income' : 'expenses'}:',
                  style: TextStyle(color: palette.muted, fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: textController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Category name',
                    hintText: 'e.g. Pet Care, Travel, Fitness',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                    fillColor: palette.surface,
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) return 'Enter a category name';
                    if (trimmed.length > 50) {
                      return 'Name too long (max 50 chars)';
                    }
                    if (_categories
                        .any((c) => c.toLowerCase() == trimmed.toLowerCase())) {
                      return 'This category already exists';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text('Cancel', style: TextStyle(color: palette.muted)),
            ),
            FilledButton(
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  Navigator.of(dialogCtx).pop(textController.text.trim());
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor:
                    _type == 'income' ? palette.blue : palette.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Add category',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (newCategory != null && newCategory.isNotEmpty) {
      setState(() {
        final list =
            _type == 'income' ? _incomeCategories : _expenseCategories;
        if (!list.contains(newCategory)) {
          final otherIdx = list.indexOf('Other');
          if (otherIdx != -1) {
            list.insert(otherIdx, newCategory);
          } else {
            list.add(newCategory);
          }
        }
        _category = newCategory;
      });
    }
  }

  Future<void> _selectDate() async {
    final palette = Theme.of(context).extension<_FinanceColors>()!;
    final now = DateTime.now();
    final lastDate = now.isBefore(_occurredAt) ? _occurredAt : now;
    final selected = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: lastDate,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
              Theme.of(context).colorScheme.copyWith(primary: palette.red),
        ),
        child: child!,
      ),
    );
    if (selected != null) {
      setState(() {
        _occurredAt = DateTime(
          selected.year,
          selected.month,
          selected.day,
          _occurredAt.hour,
          _occurredAt.minute,
        );
      });
    }
  }

  Future<void> _confirmDelete() async {
    final palette = Theme.of(context).extension<_FinanceColors>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text(
          'Delete transaction?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to delete this recorded transaction? This action cannot be undone.',
          style: TextStyle(color: palette.muted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text('Cancel', style: TextStyle(color: palette.muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: palette.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.onDelete != null) {
      setState(() {
        _deleting = true;
        _error = null;
      });
      try {
        await widget.onDelete!();
        if (mounted) Navigator.of(context).pop(true);
      } catch (error) {
        if (mounted) {
          setState(() {
            _deleting = false;
            _error = error.toString();
          });
        }
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        _TransactionDraft(
          amount: double.parse(_amountController.text.trim()),
          type: _type,
          currency: 'MYR',
          category: _category,
          occurredAt: _occurredAt,
          merchant: _optionalText(_merchantController.text),
          description: _optionalText(_descriptionController.text),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<_FinanceColors>()!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _sand,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditing ? 'Edit transaction' : 'Add transaction',
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (_isEditing && widget.onDelete != null)
                      IconButton(
                        tooltip: 'Delete transaction',
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: palette.red,
                        ),
                        onPressed:
                            (_saving || _deleting) ? null : _confirmDelete,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'expense',
                      label: Text('Expense'),
                      icon: Icon(Icons.north_east_rounded),
                    ),
                    ButtonSegment(
                      value: 'income',
                      label: Text('Income'),
                      icon: Icon(Icons.south_west_rounded),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _type = selection.first;
                      if (!_categories.contains(_category)) {
                        _category = _categories.first;
                      }
                    });
                  },
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? Colors.white
                          : palette.ink,
                    ),
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? (_type == 'income' ? palette.blue : palette.red)
                          : palette.surface,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                _formField(
                  controller: _amountController,
                  label: 'Amount (MYR)',
                  hint: '0.00',
                  icon: Icons.payments_outlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    if (amount == null || !amount.isFinite || amount <= 0) {
                      return 'Enter an amount greater than zero';
                    }
                    if (amount >= 100000000) return 'Amount is too large';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('$_type-$_category'),
                  initialValue: _categories.contains(_category)
                      ? _category
                      : _categories.first,
                  decoration: _fieldDecoration(
                    'Category',
                    Icons.grid_view_rounded,
                  ),
                  items: [
                    ..._categories.map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Icon(
                              _categoryIcon(category),
                              size: 16,
                              color: palette.muted,
                            ),
                            const SizedBox(width: 8),
                            Text(category),
                          ],
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: '__new_category__',
                      child: Row(
                        children: [
                          Icon(
                            Icons.add_circle_outline_rounded,
                            size: 16,
                            color: palette.blue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+ Add new category...',
                            style: TextStyle(
                              color: palette.blue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == '__new_category__') {
                      _showAddCategoryDialog();
                    } else if (value != null) {
                      setState(() => _category = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _formField(
                  controller: _merchantController,
                  label: 'Merchant or source (optional)',
                  icon: Icons.storefront_outlined,
                  maxLength: 255,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration:
                        _fieldDecoration('Date', Icons.calendar_today_rounded),
                    child: Text(
                      _dateLabel(_occurredAt),
                      style: TextStyle(color: palette.ink, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _formField(
                  controller: _descriptionController,
                  label: 'Note (optional)',
                  icon: Icons.notes_rounded,
                  maxLength: 1000,
                  maxLines: 2,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: palette.red, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: (_saving || _deleting) ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: (_saving || _deleting)
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEditing
                                ? 'Update transaction'
                                : 'Save transaction',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLength,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLength: maxLength,
      maxLines: maxLines,
      decoration: _fieldDecoration(label, icon).copyWith(hintText: hint),
    );
  }

  InputDecoration _fieldDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19),
        filled: true,
        fillColor: Theme.of(context).extension<_FinanceColors>()!.surface,
        counterText: '',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).extension<_FinanceColors>()!.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).extension<_FinanceColors>()!.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).extension<_FinanceColors>()!.blue,
            width: 1.5,
          ),
        ),
      );
}

double _sum(Iterable<TransactionRecord> transactions, String type) =>
    transactions
        .where((transaction) => transaction.type == type)
        .fold<double>(0, (total, transaction) => total + transaction.amount);

String _money(double value, String currency) =>
    '$currency ${value.abs().toStringAsFixed(2)}';

String _compactMoney(double value) {
  if (value >= 1000000) return 'MYR ${(value / 1000000).toStringAsFixed(1)}m';
  if (value >= 10000) return 'MYR ${(value / 1000).toStringAsFixed(1)}k';
  return 'MYR ${value.toStringAsFixed(0)}';
}

String _monthLabel(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

String _dateLabel(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

IconData _categoryIcon(String category) {
  final lower = category.toLowerCase();
  if (lower.contains('food') || lower.contains('cafe') || lower.contains('coffee') || lower.contains('restaurant')) {
    return Icons.restaurant_rounded;
  }
  if (lower.contains('grocer')) {
    return Icons.local_grocery_store_rounded;
  }
  if (lower.contains('transport') || lower.contains('petrol') || lower.contains('fuel') || lower.contains('car')) {
    return Icons.directions_car_rounded;
  }
  if (lower.contains('bill') || lower.contains('utility')) {
    return Icons.receipt_long_rounded;
  }
  if (lower.contains('shop')) {
    return Icons.shopping_bag_outlined;
  }
  if (lower.contains('health') || lower.contains('fitness') || lower.contains('gym') || lower.contains('medical')) {
    return Icons.favorite_border_rounded;
  }
  if (lower.contains('entertainment') || lower.contains('movie') || lower.contains('game')) {
    return Icons.movie_outlined;
  }
  if (lower.contains('salary') || lower.contains('wage')) {
    return Icons.work_outline_rounded;
  }
  if (lower.contains('freelance')) {
    return Icons.laptop_mac_rounded;
  }
  if (lower.contains('invest')) {
    return Icons.trending_up_rounded;
  }
  if (lower.contains('gift')) {
    return Icons.card_giftcard_rounded;
  }
  if (lower.contains('travel') || lower.contains('flight') || lower.contains('hotel')) {
    return Icons.flight_takeoff_rounded;
  }
  if (lower.contains('pet')) {
    return Icons.pets_rounded;
  }
  if (lower.contains('educat') || lower.contains('school') || lower.contains('book')) {
    return Icons.school_rounded;
  }
  if (lower.contains('transfer')) {
    return Icons.swap_horiz_rounded;
  }
  return Icons.label_outline_rounded;
}

String formatMoney(double value, String currency) => _money(value, currency);
String formatDateLabel(DateTime date) => _dateLabel(date);
String formatMonthLabel(DateTime date) => _monthLabel(date);
IconData getCategoryIcon(String category) => _categoryIcon(category);

String? _optionalText(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

class StatementImportBanner extends StatelessWidget {
  const StatementImportBanner({super.key, required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<_FinanceColors>()!;
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.document_scanner_rounded,
              color: colors.blue,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Import Statement',
                      style: TextStyle(
                        color: colors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: colors.sand.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'AI',
                        style: TextStyle(
                          color: colors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Bank or eWallet PDF, Excel, or CSV',
                  style: TextStyle(color: colors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onImport,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              side: BorderSide(color: colors.blue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Upload',
              style: TextStyle(
                color: colors.blue,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatementResultSheet extends StatelessWidget {
  const StatementResultSheet({super.key, required this.response});

  final StatementUploadResponse response;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<_FinanceColors>()!;
    final palette = colors;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: _sand,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: palette.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: palette.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        response.totalFiles > 1
                            ? (response.institutionName ??
                                '${response.totalFiles} Statements Imported')
                            : (response.institutionName ??
                                'Statement Imported'),
                        style: TextStyle(
                          color: palette.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        response.totalFiles > 1
                            ? '${response.totalFiles} statements • ${response.filename}'
                            : (response.statementPeriod ?? response.filename),
                        style: TextStyle(color: palette.muted, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _metricCard(
                    title: 'New Saved',
                    value: '${response.totalSaved}',
                    color: palette.blue,
                    icon: Icons.check_circle_outline,
                    colors: colors,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metricCard(
                    title: 'Duplicates',
                    value: '${response.duplicatesSkipped}',
                    color: palette.sand,
                    icon: Icons.copy_rounded,
                    colors: colors,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metricCard(
                    title: 'Total Income',
                    value: _compactMoney(response.totalIncome),
                    color: palette.blue,
                    icon: Icons.south_west_rounded,
                    colors: colors,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metricCard(
                    title: 'Expenses',
                    value: _compactMoney(response.totalExpense),
                    color: palette.red,
                    icon: Icons.north_east_rounded,
                    colors: colors,
                  ),
                ),
              ],
            ),
            if (response.fileSummaries.length > 1) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: response.fileSummaries.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final summary = response.fileSummaries[index];
                    final hasError = summary.error != null;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: hasError
                            ? palette.errorSurface
                            : palette.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: hasError ? palette.red : palette.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasError
                                ? Icons.error_outline
                                : Icons.description_outlined,
                            size: 13,
                            color: hasError ? palette.red : palette.blue,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            hasError
                                ? '${summary.filename} (Failed)'
                                : '${summary.institutionName ?? summary.filename}: ${summary.totalSaved} saved',
                            style: TextStyle(
                              color: hasError ? palette.red : palette.ink,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Extracted Transactions (${response.transactions.length})',
              style: TextStyle(
                color: palette.ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: response.transactions.isEmpty
                  ? Center(
                      child: Text(
                        'No transactions detected in statement.',
                        style: TextStyle(color: palette.muted),
                      ),
                    )
                  : ListView.separated(
                      itemCount: response.transactions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final tx = response.transactions[index];
                        final isExpense = tx.type == 'expense';
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: palette.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: (isExpense ? palette.red : palette.blue)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _categoryIcon(tx.category),
                                  color: isExpense ? palette.red : palette.blue,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.merchant ?? tx.description ?? 'Unknown',
                                      style: TextStyle(
                                        color: palette.ink,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          _dateLabel(tx.occurredAt),
                                          style: TextStyle(
                                            color: palette.muted,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '•  ${tx.category}',
                                          style: TextStyle(
                                            color: palette.muted,
                                            fontSize: 11,
                                          ),
                                        ),
                                        if (tx.isDuplicate) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: palette.sand
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Duplicate',
                                              style: TextStyle(
                                                color: palette.ink,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isExpense ? '−' : '+'}${_money(tx.amount, tx.currency)}',
                                style: TextStyle(
                                  color:
                                      isExpense ? palette.red : palette.blue,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.ink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required _FinanceColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: colors.muted, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: colors.ink,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

