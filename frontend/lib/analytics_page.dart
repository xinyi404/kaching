import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'api_service.dart';
import 'date_range_picker_dialog.dart';
import 'main.dart';
import 'stats_bar_chart.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({
    super.key,
    required this.transactions,
    this.api,
    this.onRefresh,
    this.initialStartDate,
    this.initialEndDate,
    this.initialPresetLabel = 'This Month',
  });

  final List<TransactionRecord> transactions;
  final FinanceApi? api;
  final Future<void> Function()? onRefresh;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final String? initialPresetLabel;

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  late DateTime _startDate;
  late DateTime _endDate;
  String? _presetLabel;
  StatsGranularity _granularity = StatsGranularity.monthly;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = widget.initialStartDate ?? DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    _endDate = widget.initialEndDate ??
        DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59);
    _presetLabel = widget.initialPresetLabel ?? 'This Month';
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

  List<TransactionRecord> get _filteredTransactions {
    return widget.transactions.where((t) {
      return !t.occurredAt.isBefore(_startDate) &&
          !t.occurredAt.isAfter(_endDate);
    }).toList();
  }

  String _formatDisplayDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatRangeLabel() {
    if (_presetLabel != null &&
        _presetLabel!.isNotEmpty &&
        _presetLabel != 'Custom') {
      return _presetLabel!;
    }
    return '${_formatDisplayDate(_startDate)} – ${_formatDisplayDate(_endDate)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FinanceColors>() ??
        FinanceColors.light;
    final filtered = _filteredTransactions;

    double totalIncome = 0;
    double totalExpense = 0;
    final Map<String, double> categoryExpenses = {};

    for (final tx in filtered) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
        categoryExpenses.update(
          tx.category,
          (val) => val + tx.amount,
          ifAbsent: () => tx.amount,
        );
      }
    }
    final netBalance = totalIncome - totalExpense;

    return Scaffold(
      backgroundColor: colors.background,
      body: RefreshIndicator(
        color: colors.primary,
        onRefresh: widget.onRefresh ?? () async {},
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            // Deep Navy Header
            _buildHeader(colors),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 4-Card Summary Grid (2x2)
                  _buildSummaryGrid(
                    colors: colors,
                    income: totalIncome,
                    expense: totalExpense,
                    net: netBalance,
                    count: filtered.length,
                  ),
                  const SizedBox(height: 16),

                  // Cash Flow Trends Chart Card
                  _buildCashFlowCard(colors, filtered),
                  const SizedBox(height: 16),

                  // Spending by Category Donut & Breakdown Card
                  _buildCategoryBreakdownCard(
                    colors: colors,
                    expenses: categoryExpenses,
                    totalExpense: totalExpense,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(FinanceColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        22,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Analytics',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              InkWell(
                onTap: _openDateRangePicker,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatRangeLabel(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Granularity Segmented Switcher (Daily, Monthly, Yearly)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                _buildGranularityTab('Daily', StatsGranularity.daily, colors),
                _buildGranularityTab(
                    'Monthly', StatsGranularity.monthly, colors),
                _buildGranularityTab('Yearly', StatsGranularity.yearly, colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGranularityTab(
    String label,
    StatsGranularity value,
    FinanceColors colors,
  ) {
    final isSelected = _granularity == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _granularity = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          height: 34,
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryGrid({
    required FinanceColors colors,
    required double income,
    required double expense,
    required double net,
    required int count,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                colors: colors,
                title: 'Total income',
                value: '+${formatMoney(income, 'MYR')}',
                valueColor: colors.green,
                icon: Icons.north_east_rounded,
                iconColor: colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                colors: colors,
                title: 'Total expenses',
                value: '−${formatMoney(expense, 'MYR')}',
                valueColor: colors.red,
                icon: Icons.south_west_rounded,
                iconColor: colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                colors: colors,
                title: 'Net balance',
                value:
                    '${net >= 0 ? '+' : '−'}${formatMoney(net.abs(), 'MYR')}',
                valueColor: net >= 0 ? colors.green : colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                colors: colors,
                title: 'Transactions',
                value: '$count',
                valueColor: colors.ink,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required FinanceColors colors,
    required String title,
    required String value,
    required Color valueColor,
    IconData? icon,
    Color? iconColor,
  }) {
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
          Text(
            title,
            style: TextStyle(
              color: colors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: iconColor),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: valueColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowCard(
    FinanceColors colors,
    List<TransactionRecord> transactions,
  ) {
    return StatsBarChartCard(
      transactions: transactions,
      initialGranularity: _granularity,
      initialStartDate: _startDate,
      initialEndDate: _endDate,
      initialPresetLabel: _presetLabel,
      showDateRangePickerButton: false,
    );
  }

  Widget _buildCategoryBreakdownCard({
    required FinanceColors colors,
    required Map<String, double> expenses,
    required double totalExpense,
  }) {
    final sortedEntries = expenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final chartColors = [
      colors.chart1,
      colors.chart2,
      colors.chart3,
      colors.chart4,
      colors.chart5,
      colors.secondary,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending by category',
            style: TextStyle(
              color: colors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          if (sortedEntries.isEmpty || totalExpense <= 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No expenses recorded in this period.',
                  style: TextStyle(color: colors.muted, fontSize: 13),
                ),
              ),
            )
          else ...[
            Row(
              children: [
                // Donut Chart
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _AnalyticsDonutPainter(
                      values: sortedEntries.map((e) => e.value).toList(),
                      colors: chartColors,
                      trackColor: colors.chartTrack,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Expenses',
                            style: TextStyle(
                              color: colors.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                formatMoney(totalExpense, 'MYR'),
                                style: TextStyle(
                                  color: colors.ink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Category List with Colored Squares
                Expanded(
                  child: Column(
                    children: [
                      for (var i = 0; i < math.min(sortedEntries.length, 5); i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: chartColors[i % chartColors.length],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  sortedEntries[i].key,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colors.ink,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${(sortedEntries[i].value / totalExpense * 100).round()}%',
                                style: TextStyle(
                                  color: colors.muted,
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
          ],
        ],
      ),
    );
  }
}

class _AnalyticsDonutPainter extends CustomPainter {
  const _AnalyticsDonutPainter({
    required this.values,
    required this.colors,
    required this.trackColor,
  });

  final List<double> values;
  final List<Color> colors;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, val) => sum + val);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (total <= 0) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14,
      );
      return;
    }

    var start = -1.5708;
    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 6.2832;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = colors[i % colors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.butt,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _AnalyticsDonutPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.colors != colors ||
      oldDelegate.trackColor != trackColor;
}
