import 'package:flutter/material.dart';

/// Preset date range options
enum DateRangePresetType {
  today,
  yesterday,
  last7Days,
  thisMonth,
  lastMonth,
  last3Months,
  allTime,
}

class DateRangePreset {
  const DateRangePreset({
    required this.type,
    required this.label,
  });

  final DateRangePresetType type;
  final String label;

  static const List<DateRangePreset> presets = [
    DateRangePreset(type: DateRangePresetType.today, label: 'Today'),
    DateRangePreset(type: DateRangePresetType.yesterday, label: 'Yesterday'),
    DateRangePreset(type: DateRangePresetType.last7Days, label: 'Last 7 days'),
    DateRangePreset(type: DateRangePresetType.thisMonth, label: 'This Month'),
    DateRangePreset(type: DateRangePresetType.lastMonth, label: 'Last Month'),
    DateRangePreset(type: DateRangePresetType.last3Months, label: 'Last 3 months'),
    DateRangePreset(type: DateRangePresetType.allTime, label: 'All Time'),
  ];

  DateTimeRange calculateRange(DateTime now) {
    switch (type) {
      case DateRangePresetType.today:
        final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case DateRangePresetType.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        final start = DateTime(yesterday.year, yesterday.month, yesterday.day, 0, 0, 0);
        final end = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case DateRangePresetType.last7Days:
        final startDay = now.subtract(const Duration(days: 6));
        final start = DateTime(startDay.year, startDay.month, startDay.day, 0, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case DateRangePresetType.thisMonth:
        final start = DateTime(now.year, now.month, 1, 0, 0, 0);
        final lastDay = DateTime(now.year, now.month + 1, 0);
        final end = DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case DateRangePresetType.lastMonth:
        final start = DateTime(now.year, now.month - 1, 1, 0, 0, 0);
        final lastDay = DateTime(now.year, now.month, 0);
        final end = DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case DateRangePresetType.last3Months:
        final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
        final start = DateTime(threeMonthsAgo.year, threeMonthsAgo.month, threeMonthsAgo.day, 0, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case DateRangePresetType.allTime:
        final start = DateTime(2000, 1, 1, 0, 0, 0);
        final end = DateTime(now.year + 5, 12, 31, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
    }
  }
}

class DateRangeResult {
  const DateRangeResult({
    required this.start,
    required this.end,
    this.presetLabel,
  });

  final DateTime start;
  final DateTime end;
  final String? presetLabel;
}

/// Displays the custom Two-Month Date Range Picker modal dialog matching the reference design,
/// laid out vertically so the user never needs to scroll horizontally to Apply or Cancel.
Future<DateRangeResult?> showCustomDateRangePicker({
  required BuildContext context,
  required DateTime initialStart,
  required DateTime initialEnd,
  String? initialPreset,
}) {
  return showDialog<DateRangeResult>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) => _DateRangePickerDialog(
      initialStart: initialStart,
      initialEnd: initialEnd,
      initialPreset: initialPreset,
    ),
  );
}

class _DateRangePickerDialog extends StatefulWidget {
  const _DateRangePickerDialog({
    required this.initialStart,
    required this.initialEnd,
    this.initialPreset,
  });

  final DateTime initialStart;
  final DateTime initialEnd;
  final String? initialPreset;

  @override
  State<_DateRangePickerDialog> createState() => _DateRangePickerDialogState();
}

class _DateRangePickerDialogState extends State<_DateRangePickerDialog> {
  late DateTime? _selectedStart;
  late DateTime? _selectedEnd;
  late String? _activePreset;

  late DateTime _leftMonth;
  late DateTime _rightMonth;

  @override
  void initState() {
    super.initState();
    _selectedStart = DateTime(
      widget.initialStart.year,
      widget.initialStart.month,
      widget.initialStart.day,
    );
    _selectedEnd = DateTime(
      widget.initialEnd.year,
      widget.initialEnd.month,
      widget.initialEnd.day,
    );
    _activePreset = widget.initialPreset;

    _leftMonth = DateTime(_selectedStart!.year, _selectedStart!.month, 1);
    _rightMonth = _addMonths(_leftMonth, 1);
  }

  static DateTime _addMonths(DateTime date, int months) {
    final year = date.year + ((date.month + months - 1) ~/ 12);
    final month = ((date.month + months - 1) % 12) + 1;
    return DateTime(year, month, 1);
  }

  void _onPresetSelected(DateRangePreset preset) {
    final range = preset.calculateRange(DateTime.now());
    setState(() {
      _selectedStart = DateTime(range.start.year, range.start.month, range.start.day);
      _selectedEnd = DateTime(range.end.year, range.end.month, range.end.day);
      _activePreset = preset.label;

      _leftMonth = DateTime(_selectedStart!.year, _selectedStart!.month, 1);
      _rightMonth = _addMonths(_leftMonth, 1);
    });
  }

  void _onDateTapped(DateTime date) {
    final tapped = DateTime(date.year, date.month, date.day);
    setState(() {
      _activePreset = null;
      if (_selectedStart == null || (_selectedStart != null && _selectedEnd != null)) {
        _selectedStart = tapped;
        _selectedEnd = null;
      } else {
        if (tapped.isBefore(_selectedStart!)) {
          _selectedEnd = _selectedStart;
          _selectedStart = tapped;
        } else {
          _selectedEnd = tapped;
        }
      }
    });
  }

  void _onApply() {
    final start = _selectedStart ?? DateTime.now();
    final end = _selectedEnd ?? start;
    final normalizedStart = DateTime(start.year, start.month, start.day, 0, 0, 0);
    final normalizedEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);

    Navigator.of(context).pop(
      DateRangeResult(
        start: normalizedStart,
        end: normalizedEnd,
        presetLabel: _activePreset,
      ),
    );
  }

  String _formatShortDate(DateTime? date) {
    if (date == null) return '--';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final now = DateTime.now();
    final monthName = months[date.month - 1];
    if (date.year == now.year) {
      return '${date.day} $monthName';
    }
    return '${date.day} $monthName ${date.year}';
  }

  static const _primaryBlue = Color(0xFF1E60E2);
  static const _rangeBlue = Color(0xFFE8F1FC);
  static const _borderColor = Color(0xFFE5E7EB);
  static const _darkText = Color(0xFF1F2937);
  static const _mutedText = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF242424) : Colors.white;
    final textDark = isDark ? const Color(0xFFF3EEE8) : _darkText;
    final borderCol = isDark ? const Color(0xFF3A3734) : _borderColor;
    final rangeBg = isDark ? const Color(0xFF1B3B6F) : _rangeBlue;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogWidth = screenWidth > 460 ? 430.0 : screenWidth - 28;
    final dialogMaxHeight = screenHeight * 0.88;

    return Dialog(
      backgroundColor: dialogBg,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderCol),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: dialogWidth,
          height: dialogMaxHeight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dialog Header: Title and Close button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Select Date Range',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).pop(),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: textDark.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Presets Bar (Horizontal scrollable chip row)
              _buildPresetsBar(textDark: textDark),

              const SizedBox(height: 6),
              Container(height: 1, color: borderCol),

              // Vertically Scrollable Calendar Area (Month 1 and Month 2 stacked vertically)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    children: [
                      // Month 1
                      _buildMonthCalendar(
                        monthDate: _leftMonth,
                        textDark: textDark,
                        rangeBg: rangeBg,
                        onPrevMonth: () {
                          setState(() {
                            _leftMonth = _addMonths(_leftMonth, -1);
                            _rightMonth = _addMonths(_leftMonth, 1);
                          });
                        },
                        onNextMonth: () {
                          setState(() {
                            _leftMonth = _addMonths(_leftMonth, 1);
                            _rightMonth = _addMonths(_leftMonth, 1);
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                      Container(height: 1, color: borderCol.withValues(alpha: 0.6)),
                      const SizedBox(height: 14),
                      // Month 2
                      _buildMonthCalendar(
                        monthDate: _rightMonth,
                        textDark: textDark,
                        rangeBg: rangeBg,
                        onPrevMonth: () {
                          setState(() {
                            _rightMonth = _addMonths(_rightMonth, -1);
                            _leftMonth = _addMonths(_rightMonth, -1);
                          });
                        },
                        onNextMonth: () {
                          setState(() {
                            _rightMonth = _addMonths(_rightMonth, 1);
                            _leftMonth = _addMonths(_rightMonth, -1);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Divider above bottom action bar
              Container(height: 1, color: borderCol),

              // Bottom Action Bar: Dates on top, Cancel & Apply on bottom (ALWAYS VISIBLE!)
              _buildBottomBar(
                borderCol: borderCol,
                textDark: textDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetsBar({required Color textDark}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBg = isDark ? const Color(0xFF333333) : const Color(0xFFF3F4F6);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: DateRangePreset.presets.map((preset) {
          final isSelected = _activePreset != null &&
              (_activePreset == preset.label ||
                  _activePreset!.toLowerCase() == preset.label.toLowerCase());
          return Material(
            color: isSelected ? _primaryBlue : unselectedBg,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _onPresetSelected(preset),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                child: Text(
                  preset.label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : textDark,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateInputBox({
    required String text,
    required Color borderCol,
    required Color textDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: borderCol, width: 1.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textDark,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBottomBar({
    required Color borderCol,
    required Color textDark,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF242424)
            : Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Selected date display [ 15 May ] — [ 15 Jun ]
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDateInputBox(
                text: _formatShortDate(_selectedStart),
                borderCol: borderCol,
                textDark: textDark,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '—',
                  style: TextStyle(
                    color: _mutedText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildDateInputBox(
                text: _formatShortDate(_selectedEnd),
                borderCol: borderCol,
                textDark: textDark,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Cancel & Apply buttons spanning full width (ALWAYS VISIBLE!)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textDark,
                    side: BorderSide(color: borderCol),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
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

  Widget _buildMonthCalendar({
    required DateTime monthDate,
    required Color textDark,
    required Color rangeBg,
    required VoidCallback onPrevMonth,
    required VoidCallback onNextMonth,
  }) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final title = '${monthNames[monthDate.month - 1]} ${monthDate.year}';
    final daysOfWeek = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

    final firstDay = DateTime(monthDate.year, monthDate.month, 1);
    final leadingDays = firstDay.weekday % 7; // Sunday = 0

    return Column(
      children: [
        // Header: <  Month Year  >
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onPrevMonth,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 22,
                  color: textDark.withValues(alpha: 0.7),
                ),
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textDark,
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onNextMonth,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: textDark.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Days of week header row (7 columns filling full width)
        Row(
          children: daysOfWeek.map((day) {
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _mutedText,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),

        // 6 rows x 7 days grid (42 cells, dynamically stretching to full width)
        Column(
          children: List.generate(6, (rowIndex) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: List.generate(7, (colIndex) {
                  final cellIndex = (rowIndex * 7) + colIndex;
                  final dayOffset = cellIndex - leadingDays;
                  final cellDate = DateTime(monthDate.year, monthDate.month, 1 + dayOffset);
                  final isCurrentMonth = cellDate.month == monthDate.month;

                  return Expanded(
                    child: _buildDayCell(
                      cellDate: cellDate,
                      colIndex: colIndex,
                      isCurrentMonth: isCurrentMonth,
                      textDark: textDark,
                      rangeBg: rangeBg,
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDayCell({
    required DateTime cellDate,
    required int colIndex,
    required bool isCurrentMonth,
    required Color textDark,
    required Color rangeBg,
  }) {
    final dateOnly = DateTime(cellDate.year, cellDate.month, cellDate.day);
    final startOnly = _selectedStart != null
        ? DateTime(_selectedStart!.year, _selectedStart!.month, _selectedStart!.day)
        : null;
    final endOnly = _selectedEnd != null
        ? DateTime(_selectedEnd!.year, _selectedEnd!.month, _selectedEnd!.day)
        : null;

    final isStart = startOnly != null && dateOnly.isAtSameMomentAs(startOnly);
    final isEnd = endOnly != null && dateOnly.isAtSameMomentAs(endOnly);
    final hasRange = startOnly != null && endOnly != null && !startOnly.isAtSameMomentAs(endOnly);
    final isInRange = startOnly != null &&
        endOnly != null &&
        dateOnly.isAfter(startOnly) &&
        dateOnly.isBefore(endOnly);

    // Range strip decorations
    Widget? rangeBackground;
    if (isInRange) {
      rangeBackground = Container(
        height: 32,
        decoration: BoxDecoration(
          color: rangeBg,
          borderRadius: BorderRadius.horizontal(
            left: colIndex == 0 ? const Radius.circular(16) : Radius.zero,
            right: colIndex == 6 ? const Radius.circular(16) : Radius.zero,
          ),
        ),
      );
    } else if (isStart && hasRange) {
      rangeBackground = Align(
        alignment: Alignment.centerRight,
        child: FractionallySizedBox(
          widthFactor: 0.5,
          child: Container(
            height: 32,
            color: rangeBg,
          ),
        ),
      );
    } else if (isEnd && hasRange) {
      rangeBackground = Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: 0.5,
          child: Container(
            height: 32,
            color: rangeBg,
          ),
        ),
      );
    }

    // Foreground day circle / text
    Widget dayForeground;
    if (isStart || isEnd) {
      dayForeground = Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: _primaryBlue,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '${cellDate.day}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    } else {
      Color textColor;
      if (isInRange) {
        textColor = _primaryBlue;
      } else if (isCurrentMonth) {
        textColor = textDark;
      } else {
        textColor = _mutedText.withValues(alpha: 0.6);
      }

      dayForeground = SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: Text(
            '${cellDate.day}',
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: isInRange ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onDateTapped(cellDate),
      child: SizedBox(
        height: 32,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (rangeBackground != null) rangeBackground,
            dayForeground,
          ],
        ),
      ),
    );
  }
}
