import 'package:flutter/material.dart';

import 'api_service.dart';
import 'date_range_picker_dialog.dart';
import 'main.dart';
import 'stats_bar_chart.dart';

/// "Show All Transactions" page with date range filtering.
/// Defaults to showing the current month.
class AllTransactionsPage extends StatefulWidget {
  const AllTransactionsPage({
    super.key,
    this.api,
    this.initialTransactions,
    this.onTransactionAdded,
  });

  final FinanceApi? api;
  final List<TransactionRecord>? initialTransactions;
  final VoidCallback? onTransactionAdded;

  @override
  State<AllTransactionsPage> createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends State<AllTransactionsPage> {
  late final FinanceApi _api;
  List<TransactionRecord> _transactions = const [];
  bool _loading = false;
  String? _loadError;

  // Date range filter: default to CURRENT MONTH
  late DateTime _startDate;
  late DateTime _endDate;
  String? _presetLabel = 'This Month';

  // Search & Type filter
  String _searchQuery = '';
  String _selectedType = 'all'; // 'all', 'expense', 'income'
  String? _selectedCategory;
  bool _showStatsChart = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? FinanceApi();

    // Default to current month:
    // start: 1st day of current month at 00:00:00
    // end: last day of current month at 23:59:59
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    _endDate = DateTime(
      lastDayOfMonth.year,
      lastDayOfMonth.month,
      lastDayOfMonth.day,
      23,
      59,
      59,
    );
    _presetLabel = 'This Month';

    if (widget.initialTransactions != null) {
      _transactions = widget.initialTransactions!;
    } else {
      _loadTransactions();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final fetched = await _api.getTransactions();
      if (mounted) {
        setState(() {
          _transactions = fetched;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = e.toString();
        });
      }
    }
  }

  Future<void> _openDateRangePicker() async {
    final result = await showCustomDateRangePicker(
      context: context,
      initialStart: _startDate,
      initialEnd: _endDate,
      initialPreset: _presetLabel,
    );

    if (result != null && mounted) {
      setState(() {
        _startDate = result.start;
        _endDate = result.end;
        _presetLabel = result.presetLabel;
      });
    }
  }

  void _resetToCurrentMonth() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
      final lastDay = DateTime(now.year, now.month + 1, 0);
      _endDate = DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59);
      _presetLabel = 'This Month';
    });
  }

  void _resetToAllTime() {
    setState(() {
      _startDate = DateTime(2000, 1, 1, 0, 0, 0);
      _endDate = DateTime(DateTime.now().year + 5, 12, 31, 23, 59, 59);
      _presetLabel = 'All Time';
    });
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
      builder: (context) => AddTransactionSheet(
        existingCategories: existingCategories,
        onSave: (draft) async {
          await _api.createTransaction(
            amount: draft.amount,
            type: draft.type,
            currency: draft.currency,
            category: draft.category,
            occurredAt: draft.occurredAt,
            merchant: draft.merchant,
            description: draft.description,
          );
        },
      ),
    );

    if (saved == true && mounted) {
      await _loadTransactions();
      widget.onTransactionAdded?.call();
    }
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
      builder: (context) => AddTransactionSheet(
        initialTransaction: transaction,
        existingCategories: existingCategories,
        onSave: (draft) async {
          await _api.updateTransaction(
            id: transaction.id,
            amount: draft.amount,
            type: draft.type,
            currency: draft.currency,
            category: draft.category,
            occurredAt: draft.occurredAt,
            merchant: draft.merchant,
            description: draft.description,
          );
        },
        onDelete: () async {
          await _api.deleteTransaction(transaction.id);
        },
      ),
    );

    if (saved == true && mounted) {
      await _loadTransactions();
      widget.onTransactionAdded?.call();
    }
  }

  List<TransactionRecord> get _filteredTransactions {
    return _transactions.where((t) {
      // Date range filter
      final inRange = !t.occurredAt.isBefore(_startDate) &&
          !t.occurredAt.isAfter(_endDate);
      if (!inRange) return false;

      // Type filter
      if (_selectedType != 'all' && t.type != _selectedType) {
        return false;
      }

      // Category filter
      if (_selectedCategory != null &&
          _selectedCategory!.isNotEmpty &&
          t.category != _selectedCategory) {
        return false;
      }

      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final merchantMatch =
            t.merchant?.toLowerCase().contains(query) ?? false;
        final categoryMatch = t.category.toLowerCase().contains(query);
        final descMatch =
            t.description?.toLowerCase().contains(query) ?? false;
        if (!merchantMatch && !categoryMatch && !descMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  String _formatDisplayDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatRangeLabel() {
    if (_presetLabel != null && _presetLabel!.isNotEmpty) {
      return _presetLabel!;
    }
    return '${_formatDisplayDate(_startDate)} – ${_formatDisplayDate(_endDate)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FinanceColors>() ??
        FinanceColors.light;
    final filtered = _filteredTransactions;

    // Calculate totals for filtered list
    double incomeTotal = 0;
    double expenseTotal = 0;
    for (final tx in filtered) {
      if (tx.type == 'income') {
        incomeTotal += tx.amount;
      } else {
        expenseTotal += tx.amount;
      }
    }
    final netCashFlow = incomeTotal - expenseTotal;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: colors.ink.withValues(alpha: 0.08),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: colors.ink),
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          'All Transactions',
          style: TextStyle(
            color: colors.ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _showStatsChart ? 'Hide stats chart' : 'Show stats chart',
            icon: Icon(
              _showStatsChart
                  ? Icons.bar_chart_rounded
                  : Icons.bar_chart_outlined,
              color: _showStatsChart ? colors.primary : colors.ink,
            ),
            onPressed: () => setState(() => _showStatsChart = !_showStatsChart),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(Icons.refresh_rounded, color: colors.ink),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: colors.red,
          onRefresh: _loadTransactions,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              // Date Range Filter Card
              _buildDateRangeFilterBar(colors),
              const SizedBox(height: 16),

              // KPI Summary Cards
              _buildSummaryCard(
                colors: colors,
                income: incomeTotal,
                expense: expenseTotal,
                net: netCashFlow,
                count: filtered.length,
              ),
              const SizedBox(height: 16),

              if (_showStatsChart) ...[
                // Stats Bar Chart
                StatsBarChartCard(
                  transactions: _transactions,
                  initialStartDate: _startDate,
                  initialEndDate: _endDate,
                  initialPresetLabel: _presetLabel,
                  showDateRangePickerButton: false,
                ),
                const SizedBox(height: 16),
              ],

              // Search & Filter controls
              _buildSearchAndChipsRow(colors),
              const SizedBox(height: 16),

              // Transaction List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transactions (${filtered.length})',
                    style: TextStyle(
                      color: colors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (_presetLabel != null &&
                      _presetLabel!.toLowerCase() != 'this month')
                    TextButton.icon(
                      onPressed: _resetToCurrentMonth,
                      icon: const Icon(Icons.calendar_today_rounded, size: 14),
                      label: const Text('Reset to Current Month'),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.blue,
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // List of transactions or empty state
              if (_loading && _transactions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(color: Color(0xFF255C99)),
                )
              else if (_loadError != null && _transactions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.errorSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Failed to load transactions: $_loadError',
                        style: TextStyle(color: colors.red, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadTransactions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (filtered.isEmpty)
                _buildEmptyState(colors)
              else
                ..._buildGroupedTransactions(filtered, colors),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'all_tx_add_fab',
        onPressed: _showAddTransaction,
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add transaction'),
      ),
    );
  }

  Widget _buildDateRangeFilterBar(FinanceColors colors) {
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _openDateRangePicker,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: colors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _formatRangeLabel(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (_presetLabel != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _presetLabel!,
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatDisplayDate(_startDate)} – ${_formatDisplayDate(_endDate)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded, size: 14, color: colors.ink),
                    const SizedBox(width: 4),
                    Text(
                      'Filter',
                      style: TextStyle(
                        color: colors.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required FinanceColors colors,
    required double income,
    required double expense,
    required double net,
    required int count,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.ink.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'PERIOD SUMMARY',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.muted.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count transaction${count == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.south_west_rounded,
                          size: 13,
                          color: colors.green,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            'Income',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: colors.muted, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '+${formatMoney(income, 'MYR')}',
                        style: TextStyle(
                          color: colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 34, color: colors.border),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.north_east_rounded,
                            size: 13,
                            color: colors.red,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              'Expenses',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: colors.muted, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '−${formatMoney(expense, 'MYR')}',
                          style: TextStyle(
                            color: colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(width: 1, height: 34, color: colors.border),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 13,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              'Net',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: colors.muted, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${net >= 0 ? '+' : '−'}${formatMoney(net.abs(), 'MYR')}',
                          style: TextStyle(
                            color: net >= 0 ? colors.green : colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndChipsRow(FinanceColors colors) {
    return Column(
      children: [
        // Search bar
        TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
          style: TextStyle(color: colors.ink, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search merchant, category, notes...',
            hintStyle: TextStyle(color: colors.muted, fontSize: 13),
            prefixIcon: Icon(Icons.search_rounded, color: colors.muted, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: colors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.blue, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Type filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTypeChip('All', 'all', colors),
              const SizedBox(width: 8),
              _buildTypeChip('Expenses', 'expense', colors),
              const SizedBox(width: 8),
              _buildTypeChip('Income', 'income', colors),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(String label, String value, FinanceColors colors) {
    final isSelected = _selectedType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedType = value),
      selectedColor: colors.primary,
      backgroundColor: colors.surface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : colors.ink,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? colors.primary : colors.border,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    );
  }

  List<Widget> _buildGroupedTransactions(
    List<TransactionRecord> transactions,
    FinanceColors colors,
  ) {
    // Group transactions by date
    final Map<String, List<TransactionRecord>> grouped = {};
    for (final tx in transactions) {
      final key = _formatDateGroupKey(tx.occurredAt);
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    final List<Widget> widgets = [];
    grouped.forEach((dateHeader, txList) {
      // Date group header
      double dayTotal = 0;
      for (final t in txList) {
        dayTotal += t.type == 'income' ? t.amount : -t.amount;
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 8, left: 4, right: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  dateHeader,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${dayTotal >= 0 ? '+' : '−'}${formatMoney(dayTotal.abs(), 'MYR')}',
                style: TextStyle(
                  color: dayTotal >= 0 ? colors.blue : colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );

      for (final tx in txList) {
        widgets.add(
          TransactionTile(
            transaction: tx,
            onTap: () => _editTransaction(tx),
          ),
        );
      }
    });

    return widgets;
  }

  String _formatDateGroupKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(date.year, date.month, date.day);

    if (txDate.isAtSameMomentAs(today)) {
      return 'Today · ${_formatDisplayDate(date)}';
    } else if (txDate.isAtSameMomentAs(yesterday)) {
      return 'Yesterday · ${_formatDisplayDate(date)}';
    }
    return _formatDisplayDate(date);
  }

  Widget _buildEmptyState(FinanceColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border),
            ),
            child: Icon(
              Icons.event_busy_rounded,
              size: 32,
              color: colors.muted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions in this period',
            style: TextStyle(
              color: colors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No transactions found for the selected date range (${_formatDisplayDate(_startDate)} – ${_formatDisplayDate(_endDate)}).',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _resetToCurrentMonth,
                icon: const Icon(Icons.calendar_month_rounded, size: 16),
                label: const Text('Current Month'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.ink,
                  side: BorderSide(color: colors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _resetToAllTime,
                icon: const Icon(Icons.all_inclusive_rounded, size: 16),
                label: const Text('View All Time'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
