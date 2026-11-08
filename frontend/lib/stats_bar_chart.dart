import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'api_service.dart';
import 'date_range_picker_dialog.dart';
import 'main.dart';

/// Supported granularities for the statistics bar chart.
enum StatsGranularity {
  daily,
  monthly,
  yearly,
}

/// A data point representing aggregated income and expenses for a time bucket.
class StatsBarData {
  const StatsBarData({
    required this.key,
    required this.label,
    required this.fullLabel,
    required this.income,
    required this.expense,
    required this.date,
  });

  final String key;
  final String label;
  final String fullLabel;
  final double income;
  final double expense;
  final DateTime date;

  double get net => income - expense;
}

/// An interactive Statistics Bar Chart card.
///
/// Features:
/// - Granularity selection: Daily, Monthly (default), Yearly.
/// - Date range filtering: defaults to current month ("This month"), opens [showCustomDateRangePicker].
/// - Side-by-side Income (blue) and Expense (red) bars.
/// - Tap on any bar to inspect exact values.
class StatsBarChartCard extends StatefulWidget {
  const StatsBarChartCard({
    super.key,
    required this.transactions,
    this.initialGranularity = StatsGranularity.monthly,
    this.initialStartDate,
    this.initialEndDate,
    this.initialPresetLabel = 'This Month',
    this.onDateRangeChanged,
    this.showDateRangePickerButton = true,
  });

  final List<TransactionRecord> transactions;
  final StatsGranularity initialGranularity;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final String? initialPresetLabel;
  final void Function(DateTime start, DateTime end, String? presetLabel)?
      onDateRangeChanged;
  final bool showDateRangePickerButton;

  @override
  State<StatsBarChartCard> createState() => _StatsBarChartCardState();
}

class _StatsBarChartCardState extends State<StatsBarChartCard> {
  late StatsGranularity _granularity;
  late DateTime _startDate;
  late DateTime _endDate;
  String? _presetLabel;
  int? _selectedBarIndex;

  @override
  void initState() {
    super.initState();
    _granularity = widget.initialGranularity;
    if (widget.initialStartDate != null && widget.initialEndDate != null) {
      _startDate = widget.initialStartDate!;
      _endDate = widget.initialEndDate!;
      _presetLabel = widget.initialPresetLabel;
    } else {
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
      final lastDay = DateTime(now.year, now.month + 1, 0);
      _endDate = DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59);
      _presetLabel = 'This Month';
    }
  }

  @override
  void didUpdateWidget(covariant StatsBarChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStartDate != null &&
        widget.initialEndDate != null &&
        (widget.initialStartDate != oldWidget.initialStartDate ||
            widget.initialEndDate != oldWidget.initialEndDate ||
            widget.initialPresetLabel != oldWidget.initialPresetLabel)) {
      _startDate = widget.initialStartDate!;
      _endDate = widget.initialEndDate!;
      _presetLabel = widget.initialPresetLabel;
      _selectedBarIndex = null;
    }
  }

  Future<void> _pickDateRange() async {
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
        _selectedBarIndex = null;
      });
      widget.onDateRangeChanged?.call(
        result.start,
        result.end,
        result.presetLabel,
      );
    }
  }

  String _formatRangeLabel() {
    if (_presetLabel != null && _presetLabel!.isNotEmpty) {
      return _presetLabel!;
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final s = '${_startDate.day} ${months[_startDate.month - 1]}';
    final e = '${_endDate.day} ${months[_endDate.month - 1]} ${_endDate.year}';
    return '$s – $e';
  }

  String _compactAmount(double value) {
    if (value >= 1000000) {
      return 'MYR ${(value / 1000000).toStringAsFixed(1)}m';
    }
    if (value >= 10000) {
      return 'MYR ${(value / 1000).toStringAsFixed(1)}k';
    }
    return 'MYR ${value.toStringAsFixed(0)}';
  }

  List<StatsBarData> _generateBuckets() {
    final inRange = widget.transactions.where((t) {
      return !t.occurredAt.isBefore(_startDate) &&
          !t.occurredAt.isAfter(_endDate);
    }).toList();

    const shortMonths = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const longMonths = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    switch (_granularity) {
      case StatsGranularity.daily:
        return _generateDailyBuckets(inRange, shortMonths);
      case StatsGranularity.monthly:
        return _generateMonthlyBuckets(inRange, shortMonths, longMonths);
      case StatsGranularity.yearly:
        return _generateYearlyBuckets(inRange);
    }
  }

  List<StatsBarData> _generateDailyBuckets(
    List<TransactionRecord> inRange,
    List<String> shortMonths,
  ) {
    final daysDiff = _endDate.difference(_startDate).inDays;
    final map = <String, ({double income, double expense, DateTime date})>{};
    for (final tx in inRange) {
      final key =
          '${tx.occurredAt.year}-${tx.occurredAt.month.toString().padLeft(2, '0')}-${tx.occurredAt.day.toString().padLeft(2, '0')}';
      final existing = map[key];
      final income =
          (existing?.income ?? 0) + (tx.type == 'income' ? tx.amount : 0);
      final expense =
          (existing?.expense ?? 0) + (tx.type == 'expense' ? tx.amount : 0);
      map[key] = (
        income: income,
        expense: expense,
        date: DateTime(
          tx.occurredAt.year,
          tx.occurredAt.month,
          tx.occurredAt.day,
        ),
      );
    }

    final buckets = <StatsBarData>[];
    if (daysDiff <= 62) {
      var current = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final endDay = DateTime(_endDate.year, _endDate.month, _endDate.day);
      while (!current.isAfter(endDay)) {
        final key =
            '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
        final data = map[key];
        final label = daysDiff <= 31
            ? '${current.day}'
            : '${current.day} ${shortMonths[current.month - 1]}';
        final fullLabel =
            '${current.day} ${shortMonths[current.month - 1]} ${current.year}';
        buckets.add(StatsBarData(
          key: key,
          label: label,
          fullLabel: fullLabel,
          income: data?.income ?? 0,
          expense: data?.expense ?? 0,
          date: current,
        ));
        current = current.add(const Duration(days: 1));
      }
    } else {
      final sortedKeys = map.keys.toList()..sort();
      for (final key in sortedKeys) {
        final data = map[key]!;
        final label = '${data.date.day} ${shortMonths[data.date.month - 1]}';
        final fullLabel =
            '${data.date.day} ${shortMonths[data.date.month - 1]} ${data.date.year}';
        buckets.add(StatsBarData(
          key: key,
          label: label,
          fullLabel: fullLabel,
          income: data.income,
          expense: data.expense,
          date: data.date,
        ));
      }
    }

    return buckets;
  }

  List<StatsBarData> _generateMonthlyBuckets(
    List<TransactionRecord> inRange,
    List<String> shortMonths,
    List<String> longMonths,
  ) {
    final map = <String, ({double income, double expense, DateTime date})>{};
    for (final tx in inRange) {
      final key =
          '${tx.occurredAt.year}-${tx.occurredAt.month.toString().padLeft(2, '0')}';
      final existing = map[key];
      final income =
          (existing?.income ?? 0) + (tx.type == 'income' ? tx.amount : 0);
      final expense =
          (existing?.expense ?? 0) + (tx.type == 'expense' ? tx.amount : 0);
      map[key] = (
        income: income,
        expense: expense,
        date: DateTime(tx.occurredAt.year, tx.occurredAt.month, 1),
      );
    }

    final buckets = <StatsBarData>[];
    var current = DateTime(_startDate.year, _startDate.month, 1);
    final endMonth = DateTime(_endDate.year, _endDate.month, 1);
    final multiYear = _startDate.year != _endDate.year;

    while (!current.isAfter(endMonth)) {
      final key =
          '${current.year}-${current.month.toString().padLeft(2, '0')}';
      final data = map[key];
      final label = multiYear
          ? '${shortMonths[current.month - 1]} \'${current.year % 100}'
          : shortMonths[current.month - 1];
      final fullLabel = '${longMonths[current.month - 1]} ${current.year}';

      buckets.add(StatsBarData(
        key: key,
        label: label,
        fullLabel: fullLabel,
        income: data?.income ?? 0,
        expense: data?.expense ?? 0,
        date: current,
      ));

      if (current.month == 12) {
        current = DateTime(current.year + 1, 1, 1);
      } else {
        current = DateTime(current.year, current.month + 1, 1);
      }
    }

    return buckets;
  }

  List<StatsBarData> _generateYearlyBuckets(List<TransactionRecord> inRange) {
    final map = <int, ({double income, double expense})>{};
    for (final tx in inRange) {
      final year = tx.occurredAt.year;
      final existing = map[year];
      final income =
          (existing?.income ?? 0) + (tx.type == 'income' ? tx.amount : 0);
      final expense =
          (existing?.expense ?? 0) + (tx.type == 'expense' ? tx.amount : 0);
      map[year] = (income: income, expense: expense);
    }

    final buckets = <StatsBarData>[];
    for (var year = _startDate.year; year <= _endDate.year; year++) {
      final data = map[year];
      buckets.add(StatsBarData(
        key: '$year',
        label: '$year',
        fullLabel: 'Year $year',
        income: data?.income ?? 0,
        expense: data?.expense ?? 0,
        date: DateTime(year, 1, 1),
      ));
    }

    return buckets;
  }

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).extension<FinanceColors>() ?? FinanceColors.light;
    final buckets = _generateBuckets();

    final totalIncome = buckets.fold<double>(0, (sum, b) => sum + b.income);
    final totalExpense = buckets.fold<double>(0, (sum, b) => sum + b.expense);
    final hasData = totalIncome > 0 || totalExpense > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Title & Date Range Filter Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: palette.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.bar_chart_rounded,
                      color: palette.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cash Flow Stats',
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              if (widget.showDateRangePickerButton)
                Flexible(
                  child: InkWell(
                    onTap: _pickDateRange,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: palette.chartTrack.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: palette.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: palette.blue,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              _formatRangeLabel(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: palette.ink,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 15,
                            color: palette.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Granularity Selector: Daily | Monthly | Yearly
          _buildGranularitySelector(palette),
          const SizedBox(height: 12),

          // Summary Legend / Totals Row
          _buildSummaryStats(palette, totalIncome, totalExpense),
          const SizedBox(height: 10),

          // Detail banner when a bar is selected
          if (_selectedBarIndex != null &&
              _selectedBarIndex! < buckets.length)
            _buildSelectedBarBanner(palette, buckets[_selectedBarIndex!]),

          // Bar Chart Visuals or Empty State
          if (!hasData)
            _buildEmptyState(palette)
          else
            _buildBarsArea(palette, buckets),
        ],
      ),
    );
  }

  Widget _buildGranularitySelector(FinanceColors palette) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.chartTrack.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _granularityOption('Daily', StatsGranularity.daily, palette),
          _granularityOption('Monthly', StatsGranularity.monthly, palette),
          _granularityOption('Yearly', StatsGranularity.yearly, palette),
        ],
      ),
    );
  }

  Widget _granularityOption(
    String title,
    StatsGranularity gran,
    FinanceColors palette,
  ) {
    final selected = _granularity == gran;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_granularity != gran) {
            setState(() {
              _granularity = gran;
              _selectedBarIndex = null;
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected ? palette.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: selected ? palette.ink : palette.muted,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStats(
    FinanceColors palette,
    double totalIncome,
    double totalExpense,
  ) {
    final net = totalIncome - totalExpense;

    return Wrap(
      spacing: 10,
      runSpacing: 4,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: palette.blue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Income: ${_compactAmount(totalIncome)}',
              style: TextStyle(
                color: palette.ink,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: palette.red,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Expense: ${_compactAmount(totalExpense)}',
              style: TextStyle(
                color: palette.ink,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Text(
          'Net: ${net >= 0 ? '+' : '−'}MYR ${net.abs().toStringAsFixed(0)}',
          style: TextStyle(
            color: net >= 0 ? palette.blue : palette.red,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedBarBanner(FinanceColors palette, StatsBarData item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.fullLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.ink,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '+MYR ${item.income.toStringAsFixed(2)}',
            style: TextStyle(
              color: palette.blue,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '−MYR ${item.expense.toStringAsFixed(2)}',
            style: TextStyle(
              color: palette.red,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() => _selectedBarIndex = null),
            child: Icon(Icons.close_rounded, size: 14, color: palette.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(FinanceColors palette) {
    return Container(
      height: 110,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 32,
            color: palette.muted.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 6),
          Text(
            'No transactions in this period',
            style: TextStyle(
              color: palette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarsArea(FinanceColors palette, List<StatsBarData> buckets) {
    final maxVal = buckets.fold<double>(
      1.0,
      (m, b) => math.max(m, math.max(b.income, b.expense)),
    );
    const chartHeight = 85.0;

    final barWidgets = <Widget>[];
    for (var i = 0; i < buckets.length; i++) {
      final b = buckets[i];
      final isSelected = _selectedBarIndex == i;

      final incomeH = b.income > 0
          ? math.max((b.income / maxVal) * chartHeight, 4.0)
          : 0.0;
      final expenseH = b.expense > 0
          ? math.max((b.expense / maxVal) * chartHeight, 4.0)
          : 0.0;

      final barWidth = buckets.length > 20 ? 4.0 : 8.0;

      final column = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _selectedBarIndex = _selectedBarIndex == i ? null : i;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          decoration: isSelected
              ? BoxDecoration(
                  color: palette.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: chartHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Income Bar
                    Container(
                      width: barWidth,
                      height: incomeH,
                      decoration: BoxDecoration(
                        color: palette.blue,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    // Expense Bar
                    Container(
                      width: barWidth,
                      height: expenseH,
                      decoration: BoxDecoration(
                        color: palette.red,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 14,
                child: Text(
                  b.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? palette.blue : palette.muted,
                    fontSize: 9,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      barWidgets.add(column);
    }

    if (buckets.length > 12) {
      return SizedBox(
        height: chartHeight + 22,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: barWidgets
                .map((w) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: SizedBox(width: 24, child: w),
                    ))
                .toList(),
          ),
        ),
      );
    }

    return SizedBox(
      height: chartHeight + 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: barWidgets.map((w) => Expanded(child: w)).toList(),
      ),
    );
  }
}
